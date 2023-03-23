/*
    AutoWire.ahk

    Autowire allows classes to require beans be instantiated in order to run. This is enforced only when AutoWire.ahk is included. This concept is similar to <a href="https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/beans/factory/annotation/Autowired.html" target="_blank">Spring Autowired in Java</a>, but instead of beans in a spring container, we just have objects declared against the global scope.

    UseCase
        - Interfaces that can be reused by lib code, where the concrete class is domain specific, where the generic code should not be dependent on domain or proprietary logic. Top level scripts can provide an implementation. In this way, top level scripts manage swapping components, not low level lib code.

    Usage:
        Include Autowire.ahk in a top level script, or before any class that has Autowiring. Afterwards, do vaidate() method. (We use deferred validation as bean defs might need the imported classes)
    Remarks
        - A global object "Autowire" will be defined, so ahk code can ignore it if Autowire.ahk is not included. Calling methods on the object will not throw the equivilent of a NPE, nor will ahk give a compile error (functions on the global scope cant be used unless explictly declared)
        - The top level script should be responsible for providing the bean definitions.
        - Using an IOC container is not needed at this point. A top level ahk script that is persistent acts like a container (Event driven).
        - Using global objects is easier and more "ahk native" than doing something like Context.getBean(SqlServiceClass)
*/
class AutoWireClass {
    __New() {
        this.beanNames:= []
    }
    
    /*
        bean

        adds bean to list of beans to validate. In absense of true ioc container, validate after all lib imports are done as Bean defs may require imports. This avoids duplicate imports by top level script, all it has to do is include a single lib export file, that has nested hierarchy of import statements.

        @param beanName - Name of object to be declared on the global scope. (Not the class name)
    */
    bean(beanName) {
        this.beanNames.push(beanName)
    }

    /*
        validate - throws error if a class calls Autowire.bean(beanName) but no object is found at global scope with that name. This method should be considered a workaround to a proper managed ioc container. See remarks on class level comment for more detail

        Remarks
            - this method might be moved to a generic ioc container class depending on if that gets implemented
    */
    validate() {
        missingBeans:= []
        for i, beanName in this.beanNames {
            ;assume bean is declared super global variable
            ref:= %beanName%
            if (!IsObject(ref)) {
                missingBeans.push(beanName)
            }
        }
        if (missingBeans.count() > 0) {
            message:= "AutoWire.ahk - BeanInstantiatedException - " missingBeans[1] " is requested but an object was not found with that name on the global scope."
            logger.error(message)
            MsgBox(message)
            ExitApp
        }
    }
}

global AutoWire:= new AutoWireClass() ;@Export AutoWire