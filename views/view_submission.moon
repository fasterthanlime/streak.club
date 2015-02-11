
SubmissionList = require "widgets.submission_list"

date = require "date"

class ViewSubmission extends require "widgets.base"
  @needs: {"submission", "streaks"}
  @include "widgets.twitter_card_helpers"
  @include "widgets.streak_helpers"

  inner_content: =>
    @content_for "meta_tags", ->
      @twitter_card_for_submission @submission

    @tweet_builder!

    if @submission\allowed_to_edit @current_user
      div class: "owner_tools", ->
        a href: @url_for("edit_submission", id: @submission.id), "Edit submission"
        raw " &middot; "
        a href: @url_for("delete_submission", id: @submission.id), "Delete submission"

    div class: "submission_column", ->
      widget SubmissionList submissions: { @submission }, show_user: true, show_comments: true

    if next @streak_submissions
      div class: "streaks_column", ->
        if #@streak_submissions == 1
          h2 "Streak"
        else
          h2 "Streaks"

        for submit in *@streak_submissions
          @render_streak_row submit.streak, date(submit.submit_time), false

  tweet_builder: =>
    return unless @current_user and @current_user\is_admin!
    div class: "tweet_builder", ->
      textarea readonly: true, ->
        text @submission\meta_title true
        hashes = ["##{s.streak.twitter_hash}" for s in *@streak_submissions when s.streak.twitter_hash]

        if next hashes
          text " "
          text table.concat hashes, " "

