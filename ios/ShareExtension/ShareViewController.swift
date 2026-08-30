import UIKit
import UniformTypeIdentifiers

/// One tool the picker can hand a shared file off to - `id` matches the
/// string the Flutter side's `ShareIntentRouter` (lib/core/share_intent/)
/// switches on, so the two lists must be kept in sync by hand (there's no
/// shared source of truth across the Swift/Dart boundary).
private struct ShareTool {
  let id: String
  let title: String
  let symbol: String
}

private let pdfTools: [ShareTool] = [
  ShareTool(id: "compress", title: "Compress PDF", symbol: "arrow.down.circle"),
  ShareTool(id: "split", title: "Split PDF", symbol: "square.split.2x1"),
  ShareTool(id: "merge", title: "Merge PDFs", symbol: "arrow.triangle.merge"),
  ShareTool(id: "edit", title: "Edit PDF", symbol: "pencil"),
  ShareTool(id: "redact", title: "Redact", symbol: "eye.slash"),
  ShareTool(id: "watermark", title: "Watermark", symbol: "rectangle.stack.badge.plus"),
  ShareTool(id: "password", title: "Password Protect", symbol: "lock"),
  ShareTool(id: "signature", title: "Digital Signature", symbol: "signature"),
  ShareTool(id: "fillsign", title: "Fill & Sign", symbol: "doc.text.fill"),
  ShareTool(id: "pageedit", title: "Edit Pages", symbol: "doc.on.doc"),
  ShareTool(id: "pdfword", title: "PDF ⇄ Word", symbol: "doc.richtext"),
]

private let imageTools: [ShareTool] = [
  ShareTool(id: "imagepdf", title: "Image ⇄ PDF", symbol: "photo"),
]

/// The Share Sheet extension's entire UI (see Info.plist's
/// NSExtensionPrincipalClass - no storyboard). Deliberately does no PDF
/// processing itself: iOS share extensions run under a tight memory limit
/// that Syncfusion + a second Flutter engine would risk blowing through on
/// a real-size file, so this only picks a tool and a destination - the
/// host app (already running the real screens) does the actual work once
/// handed off. See fillAndSignPdf's neighbors in pdf_repository_impl.dart
/// for where that processing already lives.
///
/// Hand-off mechanics: copies the shared file into the App Group container
/// (`group.com.purapdf.purapdf`, shared with Runner via each target's own
/// .entitlements), records which tool was picked in that group's shared
/// UserDefaults suite, then asks the extension context to open the host
/// app via its `purapdf://share` URL scheme (AppDelegate.swift routes
/// that to Dart, see ShareIntentService.takePendingShare's doc comment for
/// the Dart-side half of this handshake).
final class ShareViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  private let tableView = UITableView(frame: .zero, style: .insetGrouped)
  private var tools: [ShareTool] = []
  private var sharedItemProvider: NSItemProvider?
  private var isImage = false

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    title = "Share to PuraPDF+"

    navigationItem.leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped)
    )
    setUpTableView()
    resolveSharedItem()
  }

  private func setUpTableView() {
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  /// Looks at the first attachment of the first extension item to decide
  /// PDF vs. image tool list - good enough for the common single-file
  /// share case this extension's NSExtensionActivationRule already limits
  /// to (max count 1 of either kind).
  private func resolveSharedItem() {
    guard
      let item = extensionContext?.inputItems.first as? NSExtensionItem,
      let provider = item.attachments?.first
    else {
      showError("No file was shared.")
      return
    }
    sharedItemProvider = provider
    isImage = provider.hasItemConformingToTypeIdentifier(UTType.image.identifier)
      && !provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier)
    tools = isImage ? imageTools : pdfTools
    tableView.reloadData()
  }

  private func showError(_ message: String) {
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
      self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    })
    present(alert, animated: true)
  }

  @objc private func cancelTapped() {
    extensionContext?.cancelRequest(withError: NSError(domain: "PuraPDFShare", code: 0))
  }

  // MARK: - UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    tools.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let tool = tools[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = cell.defaultContentConfiguration()
    config.text = tool.title
    config.image = UIImage(systemName: tool.symbol)
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  // MARK: - UITableViewDelegate

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let tool = tools[indexPath.row]
    handOff(to: tool)
  }

  /// Loads the shared item's bytes, drops them in the App Group container,
  /// records the chosen tool, then opens the host app. Runs the (network-
  /// capable, so potentially slow for an iCloud-only file) load off the
  /// main thread implicitly - `loadFileRepresentation` already calls back
  /// on a background queue.
  private func handOff(to tool: ShareTool) {
    guard let provider = sharedItemProvider else { return }
    let typeId = isImage ? UTType.image.identifier : UTType.pdf.identifier

    provider.loadFileRepresentation(forTypeIdentifier: typeId) { [weak self] url, error in
      guard let self else { return }
      guard let url, error == nil else {
        DispatchQueue.main.async {
          self.showError("Couldn't read the shared file.")
        }
        return
      }
      // The temp file iOS hands us keeps its real extension (jpg/png/heic/
      // pdf/...) - prefer that over guessing from the abstract public.image
      // UTI, which has no single extension of its own.
      let ext = url.pathExtension.isEmpty ? (isImage ? "jpg" : "pdf") : url.pathExtension
      guard
        let containerUrl = FileManager.default.containerURL(
          forSecurityApplicationGroupIdentifier: "group.com.purapdf.purapdf"
        )
      else {
        DispatchQueue.main.async {
          self.showError("App Group container unavailable.")
        }
        return
      }

      let destDir = containerUrl.appendingPathComponent("SharedIncoming", isDirectory: true)
      try? FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
      // Fixed name (not the original filename) - only one pending share is
      // ever tracked at a time, see ShareIntentService.takePendingShare's
      // doc comment on the one-shot consume-and-clear contract.
      let destUrl = destDir.appendingPathComponent("incoming.\(ext)")
      try? FileManager.default.removeItem(at: destUrl)
      do {
        try FileManager.default.copyItem(at: url, to: destUrl)
      } catch {
        DispatchQueue.main.async {
          self.showError("Couldn't save the shared file.")
        }
        return
      }

      let defaults = UserDefaults(suiteName: "group.com.purapdf.purapdf")
      defaults?.set(destUrl.path, forKey: "pendingSharePath")
      defaults?.set(tool.id, forKey: "pendingShareTool")
      defaults?.synchronize()

      DispatchQueue.main.async {
        self.openHostAppAndFinish()
      }
    }
  }

  /// `open(_:completionHandler:)` on the extension context is the public,
  /// App-Store-safe way for an extension to ask the system to foreground
  /// its host app - no private API involved.
  private func openHostAppAndFinish() {
    guard let url = URL(string: "purapdf://share") else {
      extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
      return
    }
    extensionContext?.open(url) { [weak self] _ in
      self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
  }
}

/// The actual NSExtensionPrincipalClass (see Info.plist) - a share
/// extension with no storyboard gets no navigation bar for free, so this
/// wraps [ShareViewController] to get one (title + Cancel button) without
/// hand-authoring a storyboard.
final class ShareNavigationController: UINavigationController {
  override func viewDidLoad() {
    super.viewDidLoad()
    viewControllers = [ShareViewController()]
  }
}
