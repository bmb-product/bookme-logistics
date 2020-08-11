class API::Client::Quote::SubmissionsController < API::AuthenticatedController
  before_action :set_quote_submission, only: [:show, :edit, :update, :destroy]

  def index
    @quote_submissions = Quote::Submission.includes(:contact, :pickup_address, :delivery_address, :shipment_items)
                                          .page(params[:page])
                                          .without_count

    render json: @quote_submissions, each_serializer: Quote::SubmissionSerializer
  end

  # GET /quote/submissions/1
  # GET /quote/submissions/1.json
  def show
    render json: @quote_submission, serializer: Quote::SubmissionSerializer
  end

  # GET /quote/submissions/new
  def new
    render json: submission_params_key
  end

  # POST /quote/submissions
  # POST /quote/submissions.json
  def create
    @quote_submission = Quote::Submission.new(quote_submission_params)

    if @quote_submission.save
      render json: @quote_submission, serializer: Quote::SubmissionSerializer
    else
      render_bad_request @quote_submission.nested_errors
    end
  end

  # PATCH/PUT /quote/submissions/1
  # PATCH/PUT /quote/submissions/1.json
  def update
    if @quote_submission.update(quote_submission_params)
      render json: @quote_submission, serializer: Quote::SubmissionSerializer
    else
      render json: nested_errors(@quote_submission)
    end
  end

  # DELETE /quote/submissions/1
  # DELETE /quote/submissions/1.json
  def destroy
    @quote_submission.destroy
    render json: @quote_submission
    head :ok
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_quote_submission
    @quote_submission = Quote::Submission.find(params[:id])
  end

  def submission_params_key
    {
      pickup_address_attributes: [:id, :name, :lat, :lon],
      delivery_address_attributes: [:id, :name, :lat, :lon],
      contact_attributes: [:id, :name, :email, :phone_number, :title],
      shipment_items_attributes: [:id, :width, :length, :height, :weight, :weight_unit, :dimension_unit, :number_of_item]
    }
  end

  # Only allow a list of trusted parameters through.
  def quote_submission_params
    result = params.require(:quote_submission).permit(submission_params_key)
    result
  end

  def nested_errors(submission)
    errors = {}
    errors[:contact] = submission.contact.errors if !submission.contact.valid?
    errors[:pickup_address] = submission.pickup_address.errors if !submission.pickup_address.valid?
    errors[:delivery_address] = submission.delivery_address.errors if !submission.delivery_address.valid?

    return errors if submission.shipment_items.select {|item| !item.valid?}.empty?

    submission.shipment_items.each_with_index do |shipment_item, index|
      errors[:shipment_items] ||= {}
      errors[:shipment_items][index] = shipment_item.errors if !shipment_item.valid?
    end
    errors
  end
end
