#Include %A_LineFile%\..\Logger.ahk
#Include %A_LineFile%\..\LoggingUtils.ahk

/*
    PSRLogger

    Performance, Scalability, Reliabilty logger. Benchmark function calls

    TODO PSRLoggerClass should extend LoggerClass.
*/
class PSRLoggerClass extends ObjectBase {

    __New(workingDirectory, fileName:="PSR.log") {
        ;https://www.autohotkey.com/docs/commands/DllCall.htm#QPC
        DllCall("QueryPerformanceFrequency", "Int64*", freq)
        this.freq:= freq
        DllCall("QueryPerformanceCounter", "Int64*", firstRunTime)
        this.firstRunTime:= firstRunTime ;calculate cumulative cost on each call

        this.nodeTree:= {}
        this.currentNode:= new PSRNode({startTime: firstRunTime, name: "PSRROOT", level: 0})
        this.psrOutputContext:= new PSROutputContext(this)
        this.maxLevel:= 10
        this.logger:= new LoggerClass(workingDirectory, fileName, this.getClassName())
        this.logger.loglevel:= 4
        this.logger.shouldPrintObjects:= false ;stopgap to prevent unhandled infinite recursion (tree structure)
		OnExit(ObjBindMethod(this, "onExitCallback"), -1) ;call before logger onExit, alter the logger's buffer directly
    }

    push(ByRef psrNode) {
        DllCall("QueryPerformanceCounter", "Int64*", CounterBefore)
        psrNode.startTime:= CounterBefore
        psrNode.level:= (IsObject(this.currentNode)) ? this.currentNode.level + 1 : 1
        if (psrNode.level > this.maxLevel) {
            MsgBox("Max psr depth: " this.maxLevel)
            return
        }
        ;check max nodes
        
        this.currentNode.childNodes.push(psrNode)
        psrNode.parentNode:= this.currentNode
        this.currentNode:= psrNode
    }

    pop() {
        if (this.currentNode) {
            DllCall("QueryPerformanceCounter", "Int64*", CounterAfter)
            this.currentNode.endTime:= CounterAfter
            nodeValue:= this.currentNode.name ;dummy value
            this.psrOutputContext.addNode(this.currentNode.clone())

            this.currentNode:= this.currentNode.parentNode
        }
        return nodeValue
    }

    enter(name, thisFunc:="") {
        if (!this.logger.isDebugEnabled()) {
            return
        }
        ;this.logger.debug(name ((thisFunc) ? ("~" thisFunc) : "") " - start")
        /*
        if (!thisFunc) {
            thisFunc:= A_ThisFunc
        }
        */
        this.push(new PSRNode({name: name, thisFunc: thisFunc}))
    }

    exit(name, thisFunc:="") {
        if (!this.logger.isDebugEnabled()) {
            return
        }
        while (this.currentNode.name != (name . thisFunc) && this.currentNode.level >= 1) {
            nodeValue:= this.pop()
            ;this.logger.debug(nodeValue)
        }
        nodeValue:= this.pop()
        ;this.logger.debug(nodeValue) ;Deprecated, add to outputcontext in pop method
    }

    onExitCallback() {
        if (this.currentNode.name = "PSRROOT") {
            this.pop()
        }
        this.logger.buffer:= this.psrOutputContext.build()
    }
    getTimeInSeconds(start, end) {
        if (!start || !end) {
            return
        }
        ms:= (end - start) / this.freq
        return ms "s"
        /*
        sec:= floor(mod((ms / this.freq), 60))
        msMod:= floor((mod((ms / this.freq), 60) - sec) * this.freq)
        return sec "." msMod "s"
        */
    }

    getTimeAsString(time) {
        if (!time) {
            return "0s"
        }  
        return (time / this.freq) "s"
    }

    getTimeInMillis(start, end) {
        if (!start || !end) {
            return
        }
        ms:= end - start
        return ms "ms"
    }

    /*
        record time between start and stop, and save it to temp object used to construct log message
    */
    record(ByRef message) {
        this.records.Push([message, this.getTimeInSeconds()])
    }

    stopAndRecord(ByRef message) {
        this.stop()
        this.records.Push([message, this.getTimeInSeconds()])
    }

    stopAndRecordMillis(ByRef message) {
        this.stop()
        this.records.Push([message, this.getTimeInMillis()])
    } 

    getLogMessage() {
        msg:= ""
        for i, record in this.records {
            msg.= record[1] ": " record[2] "`n"
        }
        return msg
    }

}

class PSRNode {
    __New(cfg) {
        this.parentNode:= cfg.parentNode
        this.childNodes:= []
        this.startTime:= cfg.startTime
        this.endTime:=
        this.thisFunc:= cfg.thisFunc
        this.name:= cfg.name this.thisFunc
        this.level:= (cfg.level) ? cfg.level : 0
    }
}

class PSROutputContext {
    __New(ByRef loggerRef) {
        this.loggerRef:= loggerRef
        this.nodes:= [] ;maintain order of nodes
        this.psrKeyTimeMap:= {} ;maintain cumulative time between all functions Map<psrkey,interval> interval here is 10uS (microseconds)
        this.totalTime:= 0
    }

    addNode(ByRef psrNodeClone) {
        this.nodes.push(psrNodeClone)
    }

    /*
        @return Arr<PSRMetrics>
    */
    computeMetrics() {
        Critical
        psrMetricsList:= [] 
        for i, node in this.nodes {
            individualTime:= node.endTime - node.startTime
            oldPsrKeyTime:= (this.psrKeyTimeMap[node.name]) ? this.psrKeyTimeMap[node.name] : 0
            oldTotalTime:= this.totalTime

            newPsrKeyTime:= oldPsrKeyTime + individualTime
            newTotalTime:= node.endTime - this.loggerRef.firstRunTime

            psrMetricsList.push(new PsrMetrics(node.name, PSRLogger.getTimeAsString(individualTime), PSRLogger.getTimeAsString(newPsrKeyTime), PSRLogger.getTimeAsString(newTotalTime)))

            this.psrKeyTimeMap[node.name]:= newPsrKeyTime
            this.totalTime:= newTotalTime
        }
        Critical("Off")
        return psrMetricsList
    }

    /*
        Reduce entries down to single metric for each psr key.

        for now we are not maintaing any order by time, it is by lexicographic order of psrKeys.

        @param metricsList: Arr<PSRMetrics>
    */
    reduceMetricsByName(ByRef metricsList) {
        ;TODO sum # of function calls per psr key in the summary
        metricsByName:= {}
        for i, metrics in metricsList {
            name:= metrics.name
            metrics.callCount:= (metricsByName[name].callCount) ? ++metricsByName[name].callCount : 1
            if (metricsByName[name]) {
                if (name > metricsByName[name]) {
                    metricsByName[name]:= metrics
                }
            } else  {
                metricsByName[name]:= metrics
            }
        }
        filtered:= []
        for name, metric in metricsByName {
            filtered.push([name, metric.psrKeyTime, metric.callCount])
        }
        return filtered
    }

    /*
        @return arr2d
    */
    buildSummary(ByRef metricsList) {
        return this.reduceMetricsByName(metricsList)
    }

    build() {
        metricsList:= this.computeMetrics()

        metricsArr2d:= this.metricsListToArr2d(metricsList)
        metricsArr2d.insertAt(1, PSRMetrics.getHeaderRow())

        summaryArr2d:= this.buildSummary(metricsList)
        summaryArr2d.insertAt(1, ["functionName", "Combined Time", "Calls"])

        str:= ""
        str.= loggingUtils.prettyPrintArr2D(summaryArr2d)
        str.= "`n`n"
        str.= loggingUtils.prettyPrintArr2D(metricsArr2d)
        return str
    }

    metricsListToArr2d(ByRef metricsList) {
        metricsArr:= []
        for i, metrics in metricsList {
            metricsArr.push(metrics.toArray())
        }
        return metricsArr
    }
}
/*
    Store individual function call time, cumulative time for all psrnodes that share same psr key, and total time.
*/
class PSRMetrics {
    __New(name, individualTime, psrKeyTime, totalTime) {
        this.name:= name
        this.individualTime:= individualTime
        this.psrKeyTime:= psrKeyTime
        this.totalTime:= totalTime
    }

    getHeaderRow() {
        return ["Function", "Individual Time", "Per PsrKey Time", "Total Time"]
    }

    toArray() {
        return [this.name, this.individualTime, this.psrKeyTime, this.totalTime]
    }
}
global psrLogger:= psrLogger ;declare logger as super global so when it is instantiated, we dont need to mark it global in our methods. (Dont instantiate it now as it needs script config info (working directory))