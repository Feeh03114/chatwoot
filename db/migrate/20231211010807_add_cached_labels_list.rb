class AddCachedLabelsList < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :cached_label_list, :string
    Conversation.reset_column_information
    include_tag_cache
    backfill_cached_label_list
  end

  private

  def include_tag_cache
    return unless ActsAsTaggableOn::Taggable.const_defined?(:Cache, false)

    cache_module = ActsAsTaggableOn::Taggable.const_get(:Cache, false)
    cache_module.included(Conversation) if cache_module.respond_to?(:included)
  end

  def backfill_cached_label_list
    Conversation.find_in_batches do |batch|
      tags = ActsAsTaggableOn::Tagging.includes(:tag)
                                      .where(context: 'labels', taggable_type: 'Conversation', taggable_id: batch.map(&:id))
                                      .group_by(&:taggable_id)

      batch.each do |conversation|
        label_names = tags.fetch(conversation.id, []).map { |tagging| tagging.tag&.name }.compact
        next if label_names.empty?

        conversation.update_columns(cached_label_list: label_names.join(','))
      end
    end
  end
end
