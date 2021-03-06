
import sanitize_html from require "helpers.html"
import time_ago_in_words from require "lapis.util"

class SubmissionCommentList extends require "widgets.base"
  @needs: {"comments", "submission"}

  content: =>
    for comment in *@comments
      user = comment.user
      user_url = @url_for user
      filled = comment\filled_body @


      div {
        class: "submission_comment"
        id: "comment-#{comment.id}"
        "data-id": comment.id
        "data-author": user.username
        "data-body": filled != comment.body and comment.body or nil
      }, ->
        div class: "comment_avatar", ->
          a href: user_url, ->
            img src: comment.user\gravatar!

        div class: "comment_content", ->
          div class: "comment_head", ->
            if @current_user
              can_edit = comment\allowed_to_edit @current_user
              can_delete = @current_user.id == @submission.user_id
              div class: "comment_tools", ->
                a href: "#", class: "reply_btn", "Reply"

                if can_edit
                  span class: "edit_tool", ->
                    raw " &middot; "
                    a href: "#", class: "edit_btn", "Edit"

                if can_delete or can_edit
                  raw " &middot; "
                  a href: "#", class: "delete_btn", "Delete"

            a href: user_url, comment.user\name_for_display!
            raw " &middot; "
            span class: "comment_time", title: comment.created_at, time_ago_in_words comment.created_at

          div class: "comment_body user_formatted", ->
            raw sanitize_html filled

