# eco.* 网表级 ECO 命令族（R59 实测 help dump，FT091626）

> eco.* 用于布线后网表级工程变更（ECO）——高级能力，hqbuddy 暂未产品化；
> 需要时按下列语法现场使用（help 需带单引号前缀查内部变体）。另有
> 'eco.mindly / 'eco.pin_offset / 'eco.report_reused_cib / 'eco.rpt_conn
> 四条内部命令（无公开语法）。

## eco.clear_clock

```
[Syntax]
   eco.clear_clock 
[Arguments]
```

## eco.end

```
[Syntax]
   eco.end 
[Arguments]
```

## eco.forbid_route_node

```
[Syntax]
   eco.forbid_route_node  <node>
[Arguments]
o node
    type: string
    default value: None
```

## eco.icdelay.annotate

```
[Syntax]
   eco.icdelay.annotate 
[Arguments]
```

## eco.init

```
[Syntax]
   eco.init 
[Arguments]
```

## eco.place

```
[Syntax]
   eco.place 
[Arguments]
```

## eco.read

```
[Syntax]
   eco.read  <file_name>
[Arguments]
o file_name
    type: string
    default value: None
```

## eco.report_pin_delay

```
[Syntax]
   eco.report_pin_delay 
[Arguments]
```

## eco.route

```
[Syntax]
   eco.route 
[Arguments]
```

## eco.set_clock

```
[Syntax]
   eco.set_clock  <net> <type> [-index <index_value>]
[Arguments]
o net
    type: object_reference
    default value: None 
o type
    type: enumerated(pclk|sclk)
    default value: None 
o index
    type: integer
    default value: None
```

## eco.set_route_points

```
[Syntax]
   eco.set_route_points  <net> <node_list> <pin_list>
[Arguments]
o net
    type: string
    default value: None 
o node_list
    type: string
    default value: None 
o pin_list
    type: string
    default value: None
```

## eco.signal_probe

```
[Syntax]
   eco.signal_probe  <net> <loc> [-inv]
[Arguments]
o net
    type: string
    default value: None 
o loc
    type: string
    default value: None 
o inv
    type: switch
    default value: None
```

## eco.signal_probe.xist.seal

```
[Syntax]
   eco.signal_probe.xist.seal  <net> <loc> [-inv]
[Arguments]
o net
    type: string
    default value: None 
o loc
    type: string
    default value: None 
o inv
    type: switch
    default value: None
```

## eco.signal_probe.xist.sealion

```
[Syntax]
   eco.signal_probe.xist.sealion  <net> <loc> [-inv]
[Arguments]
o net
    type: string
    default value: None 
o loc
    type: string
    default value: None 
o inv
    type: switch
    default value: None
```
