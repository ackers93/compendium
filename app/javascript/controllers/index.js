import { application } from "./application"
import ModalController from "./modal_controller"
import MobileNavController from "./mobile_nav_controller"

application.register("modal", ModalController)
application.register("mobile-nav", MobileNavController)

export { application } 