# frozen_string_literal: true

class TopicComment < ApplicationRecord
  MINIMUM_BODY_LENGTH = 2
  EDITED_OFFSET_TIME  = 300 # 5 minutes

  belongs_to :topic, touch: true
  belongs_to :user, counter_cache: true, touch: true
  belongs_to :edited_by, class_name: "User", optional: true

  validate :body_length

  before_save    :set_default_edited_by, unless: :edited_by
  after_create   :update_topic_last_commented_at_date
  before_create  -> { user_group_comments_count.increase }
  before_destroy -> { user_group_comments_count.decrease }

  def edited?
    return false if topic.group.sample_group?

    !edited_by_author? || updated_at - created_at > EDITED_OFFSET_TIME
  end

  def edited_by_author?
    user == edited_by
  end

  def edited_at
    updated_at
  end

  private

    def body_length
      BodyLengthValidator.call(self, length: MINIMUM_BODY_LENGTH)
    end

    def set_default_edited_by
      self.edited_by = user
    end

    def update_topic_last_commented_at_date
      topic.update_attributes(last_commented_at: created_at)
    end

    def user_group_comments_count
      UserGroupCommentsCount.find_or_create_by!(user: user, group: topic.group)
    end
end
