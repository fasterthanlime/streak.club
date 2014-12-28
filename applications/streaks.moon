
lapis = require "lapis"

import respond_to, capture_errors_json, capture_errors, assert_error from require "lapis.application"
import require_login, not_found from require "helpers.app"
import trim_filter from require "lapis.util"
import assert_valid from require "lapis.validate"

import Streaks, Users from require "models"

class UsersApplication extends lapis.Application
  [new_streak: "/streaks/new"]: require_login respond_to {
    GET: =>
      render: "edit_streak"

    POST: capture_errors_json =>
      assert_valid @params, {
        {"streak", type: "table"}
      }

      streak_params = @params.streak
      trim_filter streak_params, {
        "title", "description", "short_description", "start_date", "end_date"
      }

      assert_valid streak_params, {
        {"title", exists: true, max_length: 1024}
        {"short_description", exists: true, max_length: 1024 * 10}
        {"description", exists: true, max_length: 1024 * 10}
        {"start_date", exists: true, max_length: 1024}
        {"end_date", exists: true, max_length: 1024}
      }

      streak_params.rate = "daily"

      streak_params.user_id = @current_user.id

      streak = Streaks\create streak_params
      json: {
        :streak
        -- url: @url_for(streak)
      }
  }

  [view_streak: "/streak/:id"]: capture_errors {
    on_error: =>
      not_found

    =>
      assert_valid @params, {
        {"id", is_integer: true}
      }

      @streak = assert_error Streaks\find(@params.id), "invalid streak"
      assert_error @streak\allowed_to_view @current_user

      render: true
  }

  [streaks: "/streaks"]: =>
    @pager = Streaks\paginated "order by id desc", prepare_results: (streaks) ->
      Users\include_in streaks, "user_id"
      streaks

    @streaks = @pager\get_page 1
    render: true

