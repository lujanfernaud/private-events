# frozen_string_literal: true

class GroupRolePolicy < ApplicationPolicy
  def index?
    logged_in? && is_group_owner?
  end

  private

    def is_group_owner?
      group.owner == user
    end

    def group
      @_group ||= Group.find(params[:group_id])
    end
end
