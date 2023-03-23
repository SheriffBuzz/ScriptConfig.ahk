#Include %A_LineFile%\..\Array.ahk
/*
    ModelList

    Class to wrap arr of models
*/
class ModelList extends ArrayBase {
    __New(ByRef modelList) {
        this.list:= modelList
    }

    findFirstErrorModel() {
        for i, model in this.list {
            if (model.error) {
                return model
            }
        }
    }

    findFirst(prop, value) {
        for i, model in this.list {
            if (model[prop] = value) {
                return model
            }
        }
        return
    }

    filterValue(prop, value) {
        filtered:= new ModelList([])
        for i, model in this.list {
            if (model[prop] = value) {
                filtered.list.push(model)
            }
        }
        return filtered
    }

    filteredCount(prop, value) {
        filtered:= new ModelList([])
        for i, model in this.list {
            if (model[prop] = value) {
                filtered.list.push(model)
            }
        }
        return filtered.list.count()
    }
}
