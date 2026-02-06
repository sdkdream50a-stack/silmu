class CommunityController < ApplicationController
  def index
    redirect_to guide_resources_path, allow_other_host: false
  end
end
