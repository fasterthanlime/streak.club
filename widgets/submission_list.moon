import sanitize_html, is_empty_html from require "helpers.html"
import login_and_return_url from require "helpers.app"
import to_json from require "lapis.util"

SubmissionCommenter = require "widgets.submission_commenter"

Base = require "widgets.base"

class SubmissionList extends require "widgets.base"
  @needs: {"submissions", "has_more"}

  base_widget: false

  show_streaks: true
  show_user: false
  show_comments: false

  js_init: =>
    opts = {
      page: @page or 1
    }

    "new S.SubmissionList(#{@widget_selector!}, #{to_json opts});"

  inner_content: =>
    @content_for "all_js", ->
      @include_redactor not @show_comments

    div class: "submission_list", ->
      @render_submissions!

    if @has_more
      div class: "submission_loader list_loader", ->
        text "Loading more"

    @templates!

  render_submissions: =>
    for submission in *@submissions
      has_title = submission.title
      classes = "submission_row"
      classes ..= " no_title" unless has_title

      div class: classes, ["data-submission_id"]: submission.id, ->
        div class: "user_column", ->
          a class: "user_link", href: @url_for(submission.user), ->
            img src: submission.user\gravatar!
            span class: "user_name", submission.user\name_for_display!

          has_likes = submission.likes_count > 0

          div class: "like_row #{has_likes and "has_likes" or ""}", ->
            classes = "toggle_like_btn"
            classes ..= " liked" if submission.submission_like

            a {
              "data-like_url": @url_for("submission_like", id: submission.id)
              "data-unlike_url": @url_for("submission_unlike", id: submission.id)
              href: @current_user and "#" or login_and_return_url @
              class: classes
            }, ->
              span class: "on_like icon-heart", ["data-tooltip"]: "Unlike submission"

              span class: "on_no_like icon-heart", ["data-tooltip"]: "Like submission"

            text " "
            a {
              href: @url_for("submission_likes", id: submission.id)
              class: "like_count"
              "data-tooltip": "View who liked"
              submission.likes_count
            }

        div class: "submission_content", ->
          div class: "submission_header", ->
            if submission.title
              h3 class: "submission_title", ->
                a href: @url_for(submission), submission.title

            h4 class: "submission_summary", ->
              if @show_user
                text "A submission by "
                a href: @url_for(submission.user), submission.user\name_for_display!
              else
                text "A submission"

              if @show_streaks and submission.streaks and next submission.streaks
                text " for "
                num_streaks = #submission.streaks
                for i, streak in ipairs submission.streaks
                  text " "
                  span class: "streak_title_group", ->
                    a href: @url_for(streak), streak.title

                    if submit = submission.streak_submissions and submission.streak_submissions[i]
                      text " "
                      span class: "unit_number", submit\unit_number!

            div class: "submission_meta", ->
              a {
                href: @url_for submission
                "data-tooltip": submission.created_at
                "#{@relative_timestamp submission.created_at}"
              }

              if submission\allowed_to_edit @current_user
                a {
                  href: @url_for("edit_submission", id: submission.id)
                  "data-tooltip": "Edit submission"
                  class: "icon-pencil edit_btn"
                }


          if submission.description and not is_empty_html submission.description
            div class: "user_formatted", ->
              raw sanitize_html submission.description
          elseif not (submission.uploads and next submission.uploads)
            p class: "empty_message", "This submission is empty"

          @render_uploads submission

          div class: "submission_footer", ->
            div class: "footer_inside", ->
              a {
                id: "comments-#{submission.id}"
                href: @url_for(submission) .. "#comments-#{submission.id}"
                class: "comments_toggle_btn #{@show_comments and "locked" or ""}"
                "data-comments_url": @url_for("submission_comments", id: submission.id)
                "data-template": "{{ count }} comment{{ count == 1 ? '' : 's' }}"
                "data-count": submission.comments_count
              }, ->
                text @plural submission.comments_count, "comment", "comments"

            if submission.tags and next submission.tags
              div class: "submission_tags", ->
                for tag in *submission.tags
                  a class: "submission_tag", tag.slug

          if @show_comments
            @render_comments submission


  templates: =>
    @js_template "comment_editor", ->
      div class: "comment_editor", ->
        action = @url_for("edit_comment", id: "XXX")\gsub "XXX", "{{ id }}"
        form class: "form edit_comment_form", method: "POST", :action, ->
          @csrf_input!
          div class: "input_wrapper", ->
            textarea name: "comment[body]", placeholder: "Your comment", ->
              raw "{{& body }}"

          div class: "button_row", ->
            button class: "button", "Update comment"
            text " or "
            a class: "cancel_edit_btn", href: "", "Cancel"


  render_uploads: (submission) =>
    return unless submission.uploads and next submission.uploads
    div class: "submission_uploads", ->
      for upload in *submission.uploads
          if upload\is_image!
            div class: "submission_image", ->
              a href: @url_for(upload), target: "_blank", ->
                img src: @url_for upload, "600x"
          elseif upload\is_audio!
            div class: "submission_audio", ->
              div {
                class: "play_audio_btn"
                ["data-audio_url"]: @url_for "prepare_play_audio", id: upload.id
              }, ->
                img class: "play_icon", src: "/static/images/audio_play.svg"
                img class: "pause_icon", src: "/static/images/audio_pause.svg"

              form {
                class: "download_form"
                action: @url_for "prepare_download", id: upload.id
                method: "post"
              }, ->
                @csrf_input!
                button class: "upload_download button", "Download"

              div class: "truncate_content", ->
                span class: "upload_name", upload.filename
                span class: "upload_size", @filesize_format upload.size

                div class: "audio_progress_outer", ->
                  div class: "audio_progress_inner"

          else
            form {
              class: "submission_upload"
              action: @url_for "prepare_download", id: upload.id
              method: "post"
            }, ->
              @csrf_input!
              if upload.downloads_count > 0
                div class: "upload_stats", ->
                  text @plural @number_format(upload.downloads_count),
                    "download", "downloads"

              button class: "upload_download button", "Download"
              span class: "upload_name", upload.filename
              span class: "upload_size", @filesize_format upload.size

  render_comments: (submission) =>
    widget SubmissionCommenter {
      submission: @submission
      submission_comments: @submission.comments
      has_more: @submission.has_more_comments
    }

