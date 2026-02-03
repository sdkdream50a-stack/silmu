# 계약서류 원클릭 생성기 컨트롤러
class ContractDocumentsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:generate]

  # GET /tools/contract-documents
  def index
    @contract_types = ContractDocumentService.get_all_types
  end

  # GET /contract-documents/documents/:type
  def documents
    @type = params[:type]
    @documents = ContractDocumentService.get_documents_for_type(@type)
    @stats = ContractDocumentService.get_document_stats(@type)

    respond_to do |format|
      format.html
      format.json { render json: { documents: @documents, stats: @stats } }
    end
  end

  # POST /contract-documents/generate
  def generate
    result = ContractDocumentService.generate_checklist(
      contract_type: params[:contract_type],
      contract_info: contract_info_params,
      selected_documents: params[:selected_documents]
    )

    respond_to do |format|
      format.json { render json: result }
      format.html { redirect_to contract_documents_path }
    end
  end

  private

  def contract_info_params
    {
      contract_name: params[:contract_name],
      contractor: params[:contractor],
      contract_amount: params[:contract_amount],
      contract_date: params[:contract_date],
      delivery_date: params[:delivery_date],
      department: params[:department],
      manager: params[:manager]
    }
  end
end
