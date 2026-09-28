class RedmineIssueTag < ActiveRecord::Base
  self.table_name = 'redmine_issue_tags'

  has_many :taggings,
           class_name: 'RedmineIssueTagging',
           foreign_key: :issue_tag_id,
           dependent: :restrict_with_error,
           inverse_of: :tag
  has_many :issues, through: :taggings
  has_and_belongs_to_many :trackers,
                          join_table: 'redmine_issue_tag_trackers',
                          foreign_key: :issue_tag_id,
                          association_foreign_key: :tracker_id
  before_validation :normalize_values

  validates :name, presence: true, length: {maximum: 80}
  validates :normalized_name, presence: true
  validates :color, format: {with: /\A#[0-9a-fA-F]{6}\z/}
  validates :trackers, presence: true
  validate :normalized_name_must_be_unique

  scope :active, -> { all }
  scope :sorted, -> { order(Arel.sql('LOWER(redmine_issue_tags.name) ASC')) }

  def to_s
    name
  end

  def remove_incompatible_taggings!
    compatible_issue_ids = Issue.where(tracker_id: tracker_ids).select(:id)
    taggings.where.not(issue_id: compatible_issue_ids).delete_all
  end

  private

  def normalized_name_must_be_unique
    duplicate = self.class.where(normalized_name: normalized_name).where.not(id: id).exists?
    errors.add(:name, :taken) if duplicate
  end

  def normalize_values
    self.name = name.to_s.strip.gsub(/\s+/, ' ')
    self.normalized_name = name.mb_chars.downcase.to_s
    self.color = '#3b82f6' if color.blank?
  end
end
