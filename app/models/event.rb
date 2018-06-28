class Event < ApplicationRecord
  RECENT_ATTENDEES_NUMBER = 8
  RANDOM_ATTENDEES_NUMBER = 6

  include FriendlyId
  friendly_id :slug_candidates, use: :scoped, scope: :group

  include Storext.model

  store_attributes :updated_fields do
    updated_start_date DateTime
    updated_end_date   DateTime
    updated_address    String
  end

  before_save   :titleize_title
  before_save   :check_website_url
  before_create :prepare_event_topic
  before_update :store_updated_fields
  before_update :update_event_topic
  after_save    :create_image_placeholder

  belongs_to :organizer, class_name: "User"
  belongs_to :group, touch: true

  has_one :address
  accepts_nested_attributes_for :address, update_only: true

  delegate :place_name, :street1, :street2, :city,
           :state, :post_code, :country,
           :latitude, :longitude,
           :full_address, :full_address_changed?,
            to: :address, allow_nil: true

  has_many :attendances, foreign_key: "attended_event_id"
  has_many :attendees, through: :attendances

  has_one  :image_placeholder, as: :resource, dependent: :destroy

  has_one  :event_topic, dependent: :destroy
  has_many :comments, through: :event_topic, source: "topic_comments"

  validates :title,       presence: true, length: { in: 4..140 }
  validates :description, presence: true, length: { in: 32..1000 }
  validates :image,       presence: true
  validate  :no_past_date

  scope :upcoming, -> {
    where("end_date > ?", Time.zone.now).order("start_date ASC")
  }

  scope :past, -> {
    where("end_date < ?", Time.zone.now).order("end_date ASC")
  }

  scope :three, -> {
    limit(3)
  }

  mount_uploader :image, ImageUploader
  include CarrierWave::ImageLocation
  include CarrierWave::SampleImage

  def image_base64
    return image_url(:thumb) unless image_placeholder

    image_placeholder.image_base64
  end

  def sample_resource?
    sample_event?
  end

  def user_sample_resource?
    sample_resource? && title =~ /\ASample\s/
  end

  def topic
    event_topic
  end

  def recent_attendees
    attendees.order(:created_at).limit(RECENT_ATTENDEES_NUMBER)
  end

  def random_attendees
    random_offset = rand(attendees.count - RANDOM_ATTENDEES_NUMBER)

    attendees.offset(random_offset).limit(RANDOM_ATTENDEES_NUMBER)
  end

  private

    def should_generate_new_friendly_id?
      slug.blank? || saved_change_to_title?
    end

    def slug_candidates
      [
        :title,
        [:title, :date]
      ]
    end

    def date
      start_date.strftime("%b %d %Y")
    end

    def titleize_title
      self.title = title.titleize
    end

    def check_website_url
      return if url_has_protocol? || website.empty?

      self.website = "https://" + website
    end

    def prepare_event_topic
      build_event_topic(
        user:  organizer,
        group: group,
        title: title,
        body:  description
      )
    end

    def url_has_protocol?
      website =~ /https?\:\/\//
    end

    def store_updated_fields
      clear_previously_updated_fields

      store_updated_start_date
      store_updated_end_date
      store_updated_address
    end

    def clear_previously_updated_fields
      self.updated_fields.clear
    end

    def store_updated_start_date
      self.updated_start_date = start_date if start_date_changed?
    end

    def store_updated_end_date
      self.updated_end_date = end_date if end_date_changed?
    end

    def store_updated_address
      self.updated_address = full_address if full_address_changed?
    end

    def update_event_topic
      topic.title = title if title_changed?
      topic.body = description if description_changed?
      topic.save
    end

    def create_image_placeholder
      ImagePlaceholderCreator.new(self).call
    end

    def no_past_date
      if start_date < Time.zone.now
        errors.add(:start_date, "can't be in the past")
      elsif end_date < start_date
        errors.add(:start_date, "can't be later than end date")
      end
    end
end
