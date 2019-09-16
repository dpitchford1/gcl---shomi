class Admin::FeatureFlagsController < AdminController

  before_action :set_flag, only: [:show, :edit, :update, :destroy]

  def index
    @feature_flags = Admin::FeatureFlag.all
  end

  def new
    @feature_flag = Admin::FeatureFlag.new
  end

  def create
    @feature_flag = Admin::FeatureFlag.new(flag_params)

    options = {}
    params[:options].each do |option|
      options.merge!(option) unless option.blank?
    end
    @feature_flag.options = options

    [:code, :turn_on_after, :turn_off_after].each do |key|
      if params[key].length > 0
        @feature_flag.try("#{key}=", params[key].reject(&:blank?))
      end
    end

    if @feature_flag.valid? && Admin::FeatureFlag.find(title: @feature_flag.title).first.nil? && @feature_flag.save
      redirect_to admin_feature_flags_path, notice: 'Flag was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    @feature_flag.title = flag_params[:title]
    @feature_flag.active = flag_params[:active]

    options = {}
    params[:options].each do |option|
      options.merge!(option) unless option.blank?
    end
    @feature_flag.options = options

    [:code, :turn_on_after, :turn_off_after].each do |key|
      if params[key].length > 0
        @feature_flag.try("#{key}=", params[key].reject(&:blank?))
      end
    end

    if @feature_flag.valid? && @feature_flag.save
      redirect_to admin_feature_flags_path, notice: 'Flag was successfully updated.'
    else
      render :edit
    end
  end

  def show
  end

  def destroy
    @feature_flag.delete
    redirect_to admin_feature_flags_path, notice: 'Flag was successfully destroyed.'
  end

  private

  def set_flag
    @feature_flag = Admin::FeatureFlag.find(title: params[:id]).first || Admin::FeatureFlag[params[:id]] || Admin::FeatureFlag.find(title: flag_params[:title]).first
  end

  def flag_params
    params.require(:feature_flag).permit(:title, :active, :code, :turn_on_after, :turn_off_after, :options, :option_key, :option_value).symbolize_keys
  end
end