# Tasks

## Next Action

* merge app_alt layout into app
* make footer responsive
* make sidebar responsive and dropdownable on mobile
* merge in controllers and models
* move nearest color & sandbox into admin
* #FIXME! issues

## Longer Term

* Move away from window.userToken and window.currentUserID

## Warnings

* warning: Pan.Repo.paginate/2 is undefined or private
  lib/pan_web/controllers/episode_controller.ex:11: PanWeb.EpisodeController.index/2

* warning: Pan.Repo.paginate/2 is undefined or private
  lib/pan_web/frontend_controller/episode_frontend_controller.ex:57: PanWeb.EpisodeFrontendController.index/2

* warning: Pan.Email.email_confirmation_link_html_email/2 is undefined (module Pan.Email is not available or is yet to be defined)
  lib/pan_web/frontend_controller/user_frontend_controller.ex:34: PanWeb.UserFrontendController.create/3

* warning: Pan.Email.email_confirmation_link_html_email/2 is undefined (module Pan.Email is not available or is yet to be defined)
  lib/pan_web/controllers/session_controller.ex:20: PanWeb.SessionController.create/2

* warning: Pan.Repo.paginate/2 is undefined or private
Found at 2 locations:
  lib/pan_web/frontend_controller/user_frontend_controller.ex:76: PanWeb.UserFrontendController.show/3
  lib/pan_web/frontend_controller/user_frontend_controller.ex:189: PanWeb.UserFrontendController.my_messages/3

* warning: Pan.Email.email_confirmation_link_html_email/2 is undefined (module Pan.Email is not available or is yet to be defined)
  lib/pan_web/api/controllers/user_controller.ex:142: PanWeb.Api.UserController.create/3

* warning: Pan.Repo.paginate/2 is undefined or private
  lib/pan_web/controllers/enclosure_controller.ex:10: PanWeb.EnclosureController.index/2

* warning: Pan.Email.pro_expiration_notification/1 is undefined (module Pan.Email is not available or is yet to be defined)
  lib/pan_web/models/user.ex:397: PanWeb.User.pro_expiration/0

* warning: Pan.Email.confirm_persona_claim_link_html_email/3 is undefined (module Pan.Email is not available or is yet to be defined)
  lib/pan_web/api/controllers/persona_controller.ex:330: PanWeb.Api.PersonaController.claim/3

* warning: Rout.persona_frontend_path/2 is undefined (module Rout is not available or is yet to be defined)
  lib/pan_web/templates/error/not_found.html.eex:45: PanWeb.ErrorView."not_found.html"/1

* warning: Pan.Email.confirm_persona_claim_link_html_email/3 is undefined (module Pan.Email is not available or is yet to be defined)
  lib/pan_web/frontend_controller/persona_frontend_controller.ex:311: PanWeb.PersonaFrontendController.claim/3

* warning: Pan.Repo.paginate/2 is undefined or private
Found at 2 locations:
  lib/pan_web/frontend_controller/persona_frontend_controller.ex:97: PanWeb.PersonaFrontendController.persona/3
  lib/pan_web/frontend_controller/persona_frontend_controller.ex:124: PanWeb.PersonaFrontendController.persona/3

* warning: Pan.Email.login_link_html_email/2 is undefined (module Pan.Email is not available or is yet to be defined)
  lib/pan_web/controllers/user_controller.ex:88: PanWeb.UserController.request_login_link/3

* warning: Pan.Repo.paginate/2 is undefined or private
Found at 2 locations:
  lib/pan_web/frontend_controller/podcast_frontend_controller.ex:12: PanWeb.PodcastFrontendController.index/2
  lib/pan_web/frontend_controller/podcast_frontend_controller.ex:31: PanWeb.PodcastFrontendController.show/2

* warning: Pan.Repo.paginate/2 is undefined or private
Found at 2 locations:
  lib/pan_web/frontend_controller/category_frontend_controller.ex:181: PanWeb.CategoryFrontendController.latest_episodes/2
  lib/pan_web/frontend_controller/category_frontend_controller.ex:222: PanWeb.CategoryFrontendController.latest_episodes_alt/2

* warning: Pan.Email.error_notification/3 is undefined (module Pan.Email is not available or is yet to be defined)
  lib/logger/backends/exception_notification.ex:20: Logger.Backends.ExceptionNotification.handle_event/2

* warning: Pan.Repo.paginate/2 is undefined or private
  lib/pan_web/frontend_controller/recommendation_frontend_controller.ex:26: PanWeb.RecommendationFrontendController.index/3

* warning: Pan.Repo.paginate/2 is undefined or private
  lib/pan_web/controllers/chapter_controller.ex:10: PanWeb.ChapterController.index/2

* warning: Floki.find/2 is undefined (module Floki is not available or is yet to be defined)
  lib/pan_web/frontend_views/page_frontend_view.ex:29: PanWeb.PageFrontendView.unsafe_content_for/2

* warning: Floki.raw_html/1 is undefined (module Floki is not available or is yet to be defined)
  lib/pan_web/frontend_views/page_frontend_view.ex:30: PanWeb.PageFrontendView.unsafe_content_for/2

* warning: PanWeb.QRCodeFrontendController.init/1 is undefined (module PanWeb.QRCodeFrontendController is not available or is yet to be defined)
  lib/pan_web/router.ex:194: PanWeb.Router.__checks__/0

---

* remote: GitHub found 1 vulnerability on PanoptikumIO/pan's default branch (1 low). To find out more, visit:
  remote:  <https://github.com/PanoptikumIO/pan/security/dependabot/assets/package-lock.json/ini/open>

## Things to reevalute

* Switching away from contexts?
