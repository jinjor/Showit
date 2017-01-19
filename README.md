Showit
----

[![Build Status](https://travis-ci.org/jinjor/showit.svg)](https://travis-ci.org/jinjor/showit)


WIP


## Usage

```
$ showit new sample
$ cd sample
$ showit edit hello.sw
```


## Grammer

### Function

```
:func-name | arg1 | arg2 | arg3
  arg4
  arg5
  arg6
  ...
```

```
:link | https://github.com/jinjor/Showit
  Home

:list
  One
  Two
  Three
```

### Node

```
$tag.class(frame)[key=value] | child1 | child2 ...
```

```
$link.big[href=/logo.png]
```

```
.big.center
  Hello!
```

```
.red(1).hide(2)
  This text will turn into red, and disapper!
```

### Text

```
blabla...
```

```
:text | blabla...
```

```
Hi!
  My | name
    is | John!
```

```
Hi! My name is John!
```

### Inline Function

```
I am { :b | super } excited!
```

```
I am
  :b | super
  excited!
```

### Defining Function

```
:def | func-name
  implementation
```

```
:def | show
  .hide(0).show(1) | $1
```

```
:show | Hey!
```


### Page

```
page1
--------------------

page2

--------------------
page3

```

## LICENSE

BSD3-Clause
