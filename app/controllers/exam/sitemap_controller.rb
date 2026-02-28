module Exam
  class SitemapController < ApplicationController
    layout false

    def index
      @subjects = ExamCurriculum::SUBJECTS
      @today = Time.zone.today.strftime('%Y-%m-%d')
      respond_to do |format|
        format.xml { render layout: false }
      end
    end
  end
end
