class UsersController < ApplicationController
  before_action :find_user, only: [:show, :edit, :update]
  before_action :set_event_if_coming_from_event, only: :show
  before_action :set_group_if_coming_from_group, only: :show
  after_action  :verify_authorized

  def new
    @user = User.new
    authorize @user
  end

  def create
    @user = User.new(user_params)
    authorize @user

    if @user.save
      flash[:success] = "Welcome! Please log in :)"
      redirect_to login_path
    else
      render :new
    end
  end

  def show
    redirect_to root_url unless @user
    authorize @user

    if @group || @event
      add_breadcrumbs
    end

    @attended_events = @user.past_attended_events
    @upcoming_events = @user.upcoming_attended_events
    @last_organized_events = @user.last_organized_events
  end

  def edit
    authorize @user
  end

  def update
    authorize @user

    if @user.update_attributes(user_params)
      flash[:success] = "Your details have been updated."
      redirect_to user_path(@user)
    else
      render :edit
    end
  end

  private

    def find_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:name, :email,
                                   :password, :password_confirmation,
                                   :location, :bio,
                                   :membership_request_emails,
                                   :group_membership_emails)
    end

    def set_event_if_coming_from_event
      @organized_event = params[:organized_event] || false
      @attending_event = params[:attending_event] || false

      if @organized_event || @attending_event
        @event = Event.find(@organized_event || @attending_event)
      end
    end

    def set_group_if_coming_from_group
      @organizer_of = params[:organizer_of] || false
      @member_of    = params[:member_of] || false

      if @organizer_of || @member_of
        @group = Group.find(@organizer_of || @member_of)
      end
    end

    def add_breadcrumbs
      if @organized_event
        add_event_breadcrumbs_for "Organizer"
      end

      if @attending_event
        add_event_breadcrumbs_for "Attendees", event_attendances_path(@event)
      end

      if @organizer_of || @member_of
        add_group_breadcrumbs_for "Organizers & Members",
          group_members_path(@group)
      end
    end

    def add_event_breadcrumbs_for(title, path = nil)
      @group = @event.group

      add_breadcrumb @group.name, group_path(@group)
      add_breadcrumb @event.title, group_event_path(@group, @event)
      add_breadcrumb title, path
      add_breadcrumb @user.name
    end

    def add_group_breadcrumbs_for(title, path = nil)
      add_breadcrumb @group.name, group_path(@group)
      add_breadcrumb title, path
      add_breadcrumb @user.name
    end
end
