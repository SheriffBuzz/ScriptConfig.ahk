/*
    MapList

    A MapList is an object that stores arrays as keys. Add method checks if array at a key is intialized, and creates the array if missing.

    MapList can be used for a loopmap/cache to store a list of objects.
*/
class MapList extends ObjectBase {
    addListItem(key, item) {
        if (!IsArray(this[key])) {
            this[key]:= []
        }
        this[key].push(item)
    }
    
    addAll(keyName, arr) {
        for i, element in arr {
            this.addListItem(element[keyName], element)
        }
        return this
    }

    containsItem() {

    }

    get(key) {
        return (this[key]) ? this[key] : []
    }
}
