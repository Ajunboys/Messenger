//
// Copyright (c) 2020 Related Code - http://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import ProgressHUD
import NYTPhotoViewer

//-------------------------------------------------------------------------------------------------------------------------------------------------
class PictureView: NYTPhotosViewController {

	private var isMessages = false

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func photos(picture: UIImage) -> [NYTPhoto] {

		let photoItem = NYTPhotoItem()
		photoItem.image = picture
		return [photoItem]
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	class func photos(messageId: String, chatId: String) -> (photoItems: [NYTPhoto], initialPhoto: NYTPhoto?) {

		var photoItems: [NYTPhotoItem] = []
		var initialPhoto: NYTPhotoItem? = nil

		let predicate = NSPredicate(format: "chatId == %@ AND type == %@ AND isDeleted == NO", chatId, MESSAGE_PHOTO)
		let messages = realm.objects(Message.self).filter(predicate).sorted(byKeyPath: "createdAt")

		let attributesTitle = [NSAttributedString.Key.foregroundColor: UIColor.white,
							   NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body)]
		let attributesCredit = [NSAttributedString.Key.foregroundColor: UIColor.gray,
								NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)]

		for message in messages {
			if let path = MediaDownload.pathPhoto(message.objectId) {
				let title = message.userFullname
				let credit = Convert.timestampToDayMonthTime(message.createdAt)

				let photoItem = NYTPhotoItem()
				photoItem.image = UIImage(contentsOfFile: path)
				photoItem.attributedCaptionTitle = NSAttributedString(string: title, attributes: attributesTitle)
				photoItem.attributedCaptionCredit = NSAttributedString(string: credit, attributes: attributesCredit)
				photoItem.objectId = message.objectId

				if (message.objectId == messageId) {
					initialPhoto = photoItem
				}
				photoItems.append(photoItem)
			}
		}

		if (initialPhoto == nil) { initialPhoto = photoItems.first }

		return (photoItems: photoItems, initialPhoto: initialPhoto)
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func setMessages(messages: Bool)
	{
		isMessages = messages
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()

		if (isMessages) {
			rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(actionMore))
		} else {
			rightBarButtonItem = nil
		}

		updateOverlayViewConstraints()
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override var prefersStatusBarHidden: Bool {

		return false
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	override var preferredStatusBarStyle: UIStatusBarStyle {

		return .lightContent
	}

	// MARK: - Initialization methods
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func updateOverlayViewConstraints() {

		if let overlay = overlayView {
			for constraint in overlay.constraints {
				if (constraint.firstItem is UINavigationBar) {
					if (constraint.firstAttribute == .top) {
						constraint.constant = 25
					}
				}
			}
		}
	}

	// MARK: - User actions
	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionMore() {

		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		alert.addAction(UIAlertAction(title: "Save", style: .default) { action in
			self.actionSave()
		})
		alert.addAction(UIAlertAction(title: "Share", style: .default) { action in
			self.actionShare()
		})
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

		present(alert, animated: true)
	}

	// MARK: - User actions (save)
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionSave() {

		if let photoItem = currentlyDisplayedPhoto as? NYTPhotoItem {
			if let image = photoItem.image {
				UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
			}
		}
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	@objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeMutableRawPointer?) {

		if (error != nil) {
			ProgressHUD.showError("Saving failed.")
		} else {
			ProgressHUD.showSuccess("Successfully saved.")
		}
	}

	// MARK: - User actions (share)
	//---------------------------------------------------------------------------------------------------------------------------------------------
	func actionShare() {

		if let photoItem = currentlyDisplayedPhoto as? NYTPhotoItem {
			if let image = photoItem.image {
				let activity = UIActivityViewController(activityItems: [image], applicationActivities: nil)
				present(activity, animated: true)
			}
		}
	}
}
