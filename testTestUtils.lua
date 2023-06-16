require 'testUtils'

-- Test ExtraItemsMethods
table = {"foo"}
ei = ExtraItems:new(table)
assert(ei:size() == #table)

assert(ei:get(0) == table[1])

-- Test Extra itms
ITEMNAME = "cheese poop"
extraItem = TestItem:new(ITEMNAME)
table = {extraItem}
extraItems = ExtraItems:new(table)
assert(extraItems:size() == 1)

NAME="foo"
itemWExtraItems = TestItemWithExtraItems:new("foo", extraItems)
assert( extraItems:get(0) == extraItem )
assert( itemWExtraItems:getName() == NAME )
-- Note sure if get extra items returns anything
-- if there are none
assert( itemWExtraItems:getExtraItems():size() == 1 )
assert( itemWExtraItems:haveExtraItems() == true )
