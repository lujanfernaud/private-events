class MembershipRequest < ApplicationRecord
  belongs_to :group
  belongs_to :user

  has_one :notification, dependent: :destroy

  validates_uniqueness_of :user, scope: :group,
    message: "is already a member of the group"

  scope :find_sent, -> (user) {
    includes(:group).
    where(user: user).
    order(created_at: :desc)
  }

  scope :find_received, -> (user) {
    includes(:group, :user).
    where(group: user.owned_groups).
    order(created_at: :desc)
  }
end
