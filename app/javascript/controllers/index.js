import { application } from "./application"
import ModalController from "./modal_controller"
import MobileNavController from "./mobile_nav_controller"
import BibleVersePickerController from "./bible_verse_picker_controller"
import VerseViewToggleController from "./verse_view_toggle_controller"
import RecentChaptersController from "./recent_chapters_controller"
import TopicAutocompleteController from "./topic_autocomplete_controller"
import TopicsSearchController from "./topics_search_controller"
import ThreadsSearchController from "./threads_search_controller"
import SearchController from "./search_controller"
import BibleSearchController from "./bible_search_controller"
import DropdownController from "./dropdown_controller"
import ThemeFormController from "./theme_form_controller"
import OnboardingController from "./onboarding_controller"
import ContributorAgreementController from "./contributor_agreement_controller"
import ThreadVersesExpandController from "./thread_verses_expand_controller"
import RangeBracketsController from "./range_brackets_controller"
import ChiasmLimbsController from "./chiasm_limbs_controller"
import ChiasmRangeController from "./chiasm_range_controller"
import ChiasmsSearchController from "./chiasms_search_controller"
import BulkUploadController from "./bulk_upload_controller"
import BulkUploadTabsController from "./bulk_upload_tabs_controller"
import GraphMapController from "./graph_map_controller"
import ContentTableEditorController from "./content_table_editor_controller"

application.register("modal", ModalController)
application.register("mobile-nav", MobileNavController)
application.register("bible-verse-picker", BibleVersePickerController)
application.register("verse-view-toggle", VerseViewToggleController)
application.register("recent-chapters", RecentChaptersController)
application.register("topic-autocomplete", TopicAutocompleteController)
application.register("topics-search", TopicsSearchController)
application.register("threads-search", ThreadsSearchController)
application.register("search", SearchController)
application.register("bible-search", BibleSearchController)
application.register("dropdown", DropdownController)
application.register("theme-form", ThemeFormController)
application.register("onboarding", OnboardingController)
application.register("contributor-agreement", ContributorAgreementController)
application.register("thread-verses-expand", ThreadVersesExpandController)
application.register("range-brackets", RangeBracketsController)
application.register("chiasm-limbs", ChiasmLimbsController)
application.register("chiasm-range", ChiasmRangeController)
application.register("chiasms-search", ChiasmsSearchController)
application.register("bulk-upload", BulkUploadController)
application.register("bulk-upload-tabs", BulkUploadTabsController)
application.register("graph-map", GraphMapController)
application.register("content-table-editor", ContentTableEditorController)

export { application } 