class Dashing.List extends Dashing.Widget
  ready: ->
    if @get('unordered')
      $(@node).find('ol').remove()
    else
      $(@node).find('ul').remove()
  onData: (data) ->
    sortedItems = new Batman.Set
    sortedItems.add.apply(sortedItems, data.items)
    @set 'items', sortedItems
