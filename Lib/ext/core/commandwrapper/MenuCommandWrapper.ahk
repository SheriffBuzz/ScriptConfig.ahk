/*
    Menu

    @commandWrapper
    @v2upgrade - v1 doesnt support options. Current v1 usecase doesnt use it

    https://www.autohotkey.com/docs/v2/lib/Menu.htm
*/
class Menu {
    add(menuItemName:="", labelOrFuncRef:="", options:="") {
        Menu, Tray, Add, %menuItemName%, %labelOrFuncRef%
    }
}
