function Invoke-RecycleItem{
    param(
        $Path
    )
    $shell = new-object -comobject "Shell.Application"
    $item = $shell.Namespace(0).ParseName("$path")
    $item.InvokeVerb("delete")
}