module Exam
  class SitemapController < ApplicationController
    layout false

    def index
      @subjects = ExamCurriculum::SUBJECTS
      @quiz_subjects = ExamQuestions::EXAM_SUBJECTS
      respond_to do |format|
        format.xml { render layout: false }
      end
    end
  end
end
