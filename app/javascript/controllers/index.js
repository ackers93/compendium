import { application } from "./application"
import ModalController from "./modal_controller"
import MobileNavController from "./mobile_nav_controller"
import BibleVersePickerController from "./bible_verse_picker_controller"

application.register("modal", ModalController)
application.register("mobile-nav", MobileNavController)
application.register("bible-verse-picker", BibleVersePickerController)

export { application } 