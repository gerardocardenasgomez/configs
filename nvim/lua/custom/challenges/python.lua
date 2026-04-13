-- ~/.config/nvim/lua/custom/challenges/python.lua
-- Python speedrun challenges

return {
  {
    name = 'ring buffer · python',
    prompt = 'implement a ring buffer with push, pop, is_full, and is_empty',
    language = 'python',
    comment = '#',
  },
  {
    name = 'ring buffer iterator · python',
    prompt = 'implement a ring buffer where __iter__ pops elements as it goes',
    language = 'python',
    comment = '#',
  },
  {
    name = 'ring buffer thread safe · python',
    prompt = 'implement a thread safe ring buffer with locks and a snapshot iterator that does not pop',
    language = 'python',
    comment = '#',
  },
  {
    name = 'palindrome checker · python',
    prompt = 'implement a function that returns true if a string is a palindrome, ignoring spaces and case',
    language = 'python',
    comment = '#',
  },
  {
    name = 'LRU cache · python',
    prompt = 'implement an LRU cache with get and put, O(1) for both',
    language = 'python',
    comment = '#',
  },
  {
    name = 'binary search · python',
    prompt = 'implement binary search returning the index or -1 if not found',
    language = 'python',
    comment = '#',
  },
  {
    name = 'BSP tree · python',
    prompt = 'implement a binary space partition tree with insert and query',
    language = 'python',
    comment = '#',
  },
}
