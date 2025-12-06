import { application } from "./application"
import ModalController from "./modal_controller"
import MobileNavController from "./mobile_nav_controller"
import BibleVersePickerController from "./bible_verse_picker_controller"
import VerseViewToggleController from "./verse_view_toggle_controller"
import TopicAutocompleteController from "./topic_autocomplete_controller"

application.register("modal", ModalController)
application.register("mobile-nav", MobileNavController)
application.register("bible-verse-picker", BibleVersePickerController)
application.register("verse-view-toggle", VerseViewToggleController)
application.register("topic-autocomplete", TopicAutocompleteController)

export { application } 