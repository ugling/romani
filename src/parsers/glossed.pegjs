
start
  = (nl / s)* blocks:blocks (nl / s)* { return { blocks }; }


nl
  = "\n\r" / "\r\n" / "\n" / "\r"

empty
  = nl nl+

s
  = ([ \t] / !empty nl)+

special
  = "[" / "]" / "|" / "{" / "}" / "&" / "+"

punct
  = "..." / "-" /  "," / "." / "!" / "?" / ":" / ";"

keyword
  = first:[a-zA-Z0-9] rest:[a-zA-Z0-9-_.]* { return first + rest.join(''); }

blocks
  = first:block rest:blocks { return [first].concat(rest); }
  / block:block { return [block]; }

block
  = (nl / s)* "{" (nl / s)* glossed:glossed (nl / s)* "}" (nl / s)* { return { glossed }; }
  / (nl / s)* text:text { return { text }; }

text
  = chars:( !((nl / s)* "{") char:. { return char; })+ { return chars.join(''); }

glossed
  = first:sentence empty s? rest:glossed { return [first].concat(rest); }
  / sentence:sentence { return [sentence]; }

sentence
  = first:chunk s? rest:sentence { return [first].concat(rest); }
  / chunk:chunk { return [chunk]; }

chunk
  = punct:punct { return { punct }; }
  / sandhi:sandhi { return { sandhi }; }
  / word:word { return { word }; }

word
  = "[" base:word "]" suffix:morph { return { base, suffix }; }
  / prefix:morph "[" base:word "]" { return { prefix, base }; }
  / root:morph { return { root }; }

sandhi
  = s? "+" s?

morph
  = form:form "|" refs:refs { return { form, refs }; }
  / form:nonemptyform { return { form, refs: [form] }; }

form
  = chars:formchar* { return chars.join(''); }

nonemptyform
  = chars:formchar+ { return chars.join(''); }

formchar
  = !punct !special !empty !s char:. { return char; }

refs
  = first:nonemptyform "&" rest:refs { return [first].concat(rest); }
  / form:nonemptyform { return [form]; }
