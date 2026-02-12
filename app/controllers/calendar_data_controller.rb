class CalendarDataController < ApplicationController
  before_action :authenticate_user!
  wrap_parameters false

  def show
    datum = current_user.calendar_datum
    if datum
      render json: {
        task_states: datum.task_states,
        custom_tasks: datum.custom_tasks,
        categories: datum.categories,
        standing_checklist: datum.standing_checklist || []
      }
    else
      render json: { task_states: {}, custom_tasks: [], categories: {}, standing_checklist: [] }
    end
  end

  def update
    datum = current_user.calendar_datum || current_user.build_calendar_datum
    body = JSON.parse(request.body.read)

    allowed = {}
    allowed[:task_states] = body["task_states"] if body.key?("task_states")
    allowed[:custom_tasks] = body["custom_tasks"] if body.key?("custom_tasks")
    allowed[:categories] = body["categories"] if body.key?("categories")
    allowed[:standing_checklist] = body["standing_checklist"] if body.key?("standing_checklist")

    if datum.update(allowed)
      render json: { ok: true }
    else
      render json: { error: datum.errors.full_messages }, status: :unprocessable_entity
    end
  rescue JSON::ParserError
    render json: { error: "Invalid JSON" }, status: :bad_request
  end
end
