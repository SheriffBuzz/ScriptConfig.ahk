#Include %A_LineFile%\..\Object.ahk

/*
    Cache.ahk

    Generic cache class, to cache ArrayBase. Pass props to the constructor to creation partitionMaps for fast lookup by a particular prop.

    This class does not evict records from the cache. It is designed for fast lookups on datasets that can be maintained in memory. Partitions are backed by the internal list structure, so memory usage should be relatively low, even as more partitionMaps are used.
*/
class CacheClass extends ObjectBase {
    /*
        Constructor

        @param data - ArrayBase
        @param partitionProps - props to pass to create a partition on. an instance prop called "partitionBy{propName}" will be created.
    */
    __New(ByRef data:="", partitionProps:="") {
        this.data:= ArrDefault(data)
        this.partitionProps:= ArrDefault(partitionProps)
        this.INFO("Loaded " this.data.count() " items")
        this.load()
    }

    /*
        @param addAll: arr
    */
    addAll(data, refresh:=false) {
        this.data.addAll(data)
        if (refresh) {
            this.load()
        }
    }

    load() {
        psrKey:= this.__Class "~load"
        psrLogger.enter(psrKey)
        for i, prop in this.partitionProps {
            this["partitionBy" prop]:= this.data.partition(prop)
        }
        psrLogger.exit(psrKey)
    }

    /*
        lookup

        do cache lookup using an internally tracked partition map. Additional error logging if requesting a prop that hasnt been indexed.

        Remarks - cache load/refresh is not handled, it is up to the caller

        @param propName
        @key
        @return ArrayBase
    */
    lookup(propName, key) {
        prop:= "partitionBy" propName
        if (!IsObject(this[prop])) {
            this.FATAL("Lookup failed by prop: " propName ". The cache was not partitioned by that property.")
            return
        }
        ;TODO log message if partition is empty or not present for @param key
        return this[prop][key]
    }
}
