
class frozendict(object):
    __slots__ = ["_dict", "_cached_hash"]

    def __init__(self, new_dict=None, **kwargs):
        self._dict = dict()
        if new_dict is not None:
            self._dict.update(new_dict)
        self._dict.update(kwargs)

    def update(self, new_dict=None, **kwargs):
        d = self._dict.copy()

        if new_dict is not None:
            d.update(new_dict)
        d.update(kwargs)

        return self.__class__(d)

    def remove(self, ks):
        d = self._dict.copy()
        for k in ks:
            if k in d:
                del d[k]
        return self.__class__(d)

    def pop(self, *ks):
        result = []
        for k in ks:
            result.append(self[k])
        result.append(self.remove(*ks))
        return result

    def __repr__(self):
        return repr(self._dict)

    def __iter__(self):
        return iter(self._dict)

    def __contains__(self, key):
        return key in self._dict

    def keys(self):
        return self._dict.keys()

    def values(self):
        return self._dict.values()

    def items(self):
        return self._dict.items()

    def iterkeys(self):
        return self._dict.iterkeys()

    def itervalues(self):
        return self._dict.itervalues()

    def iteritems(self):
        return self._dict.iteritems()

    def get(self, key, default=None):
        return self._dict.get(key, default)

    def __getitem__(self, item):
        return self._dict[item]

    def __hash__(self):
        try:
            return self._cached_hash
        except AttributeError:
            h = self._cached_hash = hash(frozenset(self._dict.items()))
            return h

    def __eq__(self, other):
        return self._dict == other._dict

    def __ne__(self, other):
        return self._dict != other._dict

    def __len__(self):
        return len(self._dict)

