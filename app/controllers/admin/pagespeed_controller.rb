# frozen_string_literal: true

# Sprint #3-A — Core Web Vitals 모니터링 (Osmani 권위자 검증)
class Admin::PagespeedController < Admin::BaseController
  def index
    @overview = SeoMonitor.pagespeed_silmu_overview
    @main = @overview.find { |o| o[:url] == SeoMonitor::SITE_URL }
  rescue => e
    Rails.logger.error "[Admin::PagespeedController] #{e.message}"
    @overview = []
    @main = nil
    flash.now[:alert] = "PageSpeed 데이터를 불러올 수 없습니다 (#{e.class})"
  end

  # AJAX refresh — 캐시 무효화 후 재측정
  def refresh
    Rails.cache.delete_matched("pagespeed/*") rescue nil
    redirect_to admin_pagespeed_index_path, notice: "PageSpeed 캐시를 초기화했습니다. 재측정에 30~60초 소요됩니다."
  end
end
