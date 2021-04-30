# Tasks

## Next Action

* move nearest color & sandbox into admin
* Feed:    <%= link "Make primary", to: feed_path(@conn, :make_only, feed),
                                    class: "btn btn-warning btn-xs",
                                    method: :post %>
* #FIXME! issues

## Longer Term

* Leverage svg-Logo and remove old png-assets.
* Move away from window.userToken and window.currentUserID

## Warnings

* remote: GitHub found 1 vulnerability on PanoptikumIO/pan's default branch (1 low). To find out more, visit:
  remote:  <https://github.com/PanoptikumIO/pan/security/dependabot/assets/package-lock.json/ini/open>

## Extend cookie warning

* LiveViews need cookies
