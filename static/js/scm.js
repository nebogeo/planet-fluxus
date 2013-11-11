// Planet Fluxus Copyright (C) 2013 Dave Griffiths
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
///////////////////////////////////////////////////////////////////////////

// a scheme compiler for javascript

var zc = {};

// match up cooresponding bracket to extract sexpr from a string
zc.extract_sexpr = function(pos, str) {
    var ret="";
    var depth=0;
    var count=0;
    for (var i=pos; i<str.length; i++) {
        if (str[i]==="(") {
            depth++;
        } else {
            if (str[i]===")") {
                depth--;
            }
        }
        ret+=str[i];
        if (depth===0) {
            return ret;
        }
        count++;
    }
    return ret;
};

function white_space(s) {
  return /\s/g.test(s);
}

zc.parse_tree = function(str) {
    var state="none";
    var in_quotes=false;
    var in_comment=false;
    var current_token="";
    var ret=[];
    var i=1;
    while (i<str.length) {
        switch (state) {
        case "none": {
            // look for a paren start
            if (i>0 && str[i]==="(") {
                var sexpr=zc.extract_sexpr(i, str);
                ret.push(zc.parse_tree(sexpr));
                i+=sexpr.length-1;
            } else if (!white_space(str[i]) &&
                       str[i]!=")") {
                state="token";
                current_token+=str[i];
                if (str[i]==="\"") in_quotes = true;
                if (str[i]===";") in_comment = true;
            }
        } break;

        case "token": {
            if (in_comment) {
                if (str[i]==="\n") {
                    state="none";
                    in_comment=false;
                }
            }
            else
            {
                if ((in_quotes && str[i]==="\"") ||
                    (!in_quotes &&
                     (str[i]===" " ||
                      str[i]===")" ||
                      str[i]==="\n"))) {
                    state="none";
                    if (in_quotes) {
                        //console.log(current_token);
                        ret.push(current_token+"\"");
                    in_quotes=false;
                    } else {
                        if (current_token!="") {
                            if (current_token=="#t") current_token="true";
                            if (current_token=="#f") current_token="false";
                            ret.push(current_token);
                        }
                    }
                    current_token="";
                } else {
                    if (in_quotes) {
                        current_token+=str[i];
                    } else {
                        switch (str[i]) {
                        case "-":
                            // don't convert - to _ in front of numbers...
                            // (this should be less naive)
                            if (i<str.length-1 &&
                                !zc.char_is_number(str[i])) {
                                current_token+="_";
                            } else {
                                current_token+=str[i];
                            }
                            break;
                        case "?": current_token+="_q"; break;
                        case "!": current_token+="_e"; break;
                        default: current_token+=str[i];
                        }
                    }
                }
            }
        } break;
        }
        i++;
    }
    return ret;
};

zc.car = function(l) { return l[0]; };

zc.cdr = function(l) {
    if (l.length<2) return [];
    var r=[];
    for (var i=1; i<l.length; i++) {
        r.push(l[i]);
    }
    return r;
};

zc.cadr = function(l) {
    return zc.car(zc.cdr(l));
};

zc.caddr = function(l) {
    return zc.car(zc.cdr(zc.cdr(l)));
};

zc.list_map = function(fn, l) {
    var r=[];
    l.forEach(function (i) {
        r.push(fn(i));
    });
    return r;
};

zc.list_contains = function(l,i) {
    return l.indexOf(i) >= 0;
};

zc.sublist = function(l,s,e) {
    var r=[];
    if (e==null) e=l.length;
    for (var i=s; i<e; i++) {
        r.push(l[i]);
    }
    return r;
};

zc.infixify = function(jsfn, args) {
    var cargs = [];
    args.forEach(function(arg) { cargs.push(zc.comp(arg)); });
    return "("+cargs.join(" "+jsfn+" ")+")";
};

zc.check = function(fn,args,min,max) {
    if (args.length<min) {
        zc.to_page("output", fn+" has too few args ("+args+")");
        return false;
    }
    if (max!=-1 && args.length>max) {
        zc.to_page("output", fn+" has too many args ("+args+")");
        return false;
    }
    return true;
};

// ( (arg1 arg2 ...) body ...)

zc.comp_lambda = function(args) {
    var expr=zc.cdr(args);
    var nexpr=expr.length;
    var last=expr[nexpr-1];
    var eexpr=zc.sublist(expr,0,nexpr-1);

    return "function ("+zc.car(args).join()+")\n"+
        // adding semicolon here
        "{"+zc.list_map(zc.comp,eexpr).join(";\n")+"\n"+
        "return "+zc.comp(last)+"\n}\n";
};

// ( body ... )
// not used... yet
zc.comp_begin = function(args) {
    var expr=args;
    var nexpr=expr.length;
    var last=expr[nexpr-1];
    var eexpr=zc.sublist(expr,0,nexpr-1);

    return "function ()\n"+
        // adding semicolon here
        "{"+zc.list_map(zc.comp,eexpr).join(";\n")+"\n"+
        "return "+zc.comp(last)+"\n}\n";
}

// ( ((arg1 exp1) (arg2 expr2) ...) body ...)
zc.comp_let = function(args) {
    var fargs = zc.car(args);
    largs = [];
    fargs.forEach(function(a) { largs.push(a[0]); });
    return "("+zc.comp_lambda([largs].concat(zc.cdr(args)))+"("+
        zc.list_map(function(a) { return zc.comp(a[1]); },fargs)+" ))\n";
};

// ( ((pred) body ...)
//   ((pred) body ...)
//   (else body ... ))

zc.comp_cond = function(args) {
    if (zc.car(zc.car(args))==="else") {
        return "(function () { return "+zc.comp(zc.cdr(zc.car(args)))+"})()";
    } else {
        return "(function () { if ("+zc.comp(zc.car(zc.car(args)))+") {\n"+
            // todo: decide if lambda, let or begin is canonical way to do this...
            "return "+zc.comp_let([[]].concat(zc.cdr(zc.car(args))))+
            "\n} else {\n"+
            "return "+zc.comp_cond(zc.cdr(args))+"\n}})()";
    }
};

zc.comp_if = function(args) {
    return "(function () { if ("+zc.comp(zc.car(args))+") {\n"+
        "return "+zc.comp(zc.cadr(args))+"} else {"+
        "return "+zc.comp(zc.caddr(args))+"}})()";
};

zc.comp_when = function(args) {
    return "(function () { if ("+zc.comp(zc.car(args))+") {\n"+
        "return ("+zc.comp_lambda([[]].concat(zc.cdr(args)))+")() }})()";
};

zc.core_forms = function(fn, args) {
    // core forms
    if (fn == "lambda") if (zc.check(fn,args,2,-1)) return zc.comp_lambda(args);
    if (fn == "if") if (zc.check(fn,args,3,3)) return zc.comp_if(args);
    if (fn == "when") if (zc.check(fn,args,2,-1)) return zc.comp_when(args);
    if (fn == "cond") if (zc.check(fn,args,2,-1)) return zc.comp_cond(args);
    if (fn == "let") if (zc.check(fn,args,2,-1)) return zc.comp_let(args);

    if (fn == "define") {
        // adding semicolon here
        if (zc.check(fn,args,2,-1)) return "var "+zc.car(args)+" = "+zc.comp(zc.cdr(args))+";";
    }

    if (fn == "list") {
        return "["+zc.list_map(zc.comp,args).join(",")+"]";
    }

    if (fn == "begin") {
        return "("+zc.comp_lambda([[]].concat(args))+")()";
    }

    if (fn == "list_ref") {
        if (zc.check(fn,args,2,2)) return zc.comp(zc.car(args))+"["+zc.comp(zc.cadr(args))+"]";
    }

    if (fn == "list_replace") {
        if (zc.check(fn,args,3,3))
            return "(function() {"+
            "var _list_replace="+zc.comp(zc.car(args))+"\n"+
            "_list_replace["+zc.comp(zc.cadr(args))+"]="+
            zc.comp(zc.caddr(args))+";\n"+
            "return _list_replace;\n})()\n";
    }

    // iterative build-list version for optimisation
    if (fn == "build_list") {
        if (zc.check(fn,args,2,2))
            return "(function() {\n"+
            "var _build_list_l="+zc.comp(zc.car(args))+";\n"+
            "var _build_list_fn="+zc.comp(zc.cadr(args))+";\n"+
            "var _build_list_r= Array(_build_list_l);\n"+
            "for (var _build_list_i=0; _build_list_i<_build_list_l; _build_list_i++) {\n"+
            "_build_list_r[_build_list_i]=_build_list_fn(_build_list_i); }\n"+
            "return _build_list_r; })()";
    }

    // iterative fold version for optimisation
    if (fn == "foldl") {
        if (zc.check(fn,args,3,3))
            return "(function() {\n"+
            "var _foldl_fn="+zc.comp(zc.car(args))+";\n"+
            "var _foldl_val="+zc.comp(zc.cadr(args))+";\n"+
            "var _foldl_src="+zc.comp(zc.caddr(args))+";\n"+
            "for (var _foldl_i=0; _foldl_i<_foldl_src.length; _foldl_i++) {\n"+
            "_foldl_val=_foldl_fn(_foldl_src[_foldl_i],_foldl_val); }\n"+
            "return _foldl_val; })()";
    }

    if (fn == "list_q") {
        if (zc.check(fn,args,1,1))
            return "(Object.prototype.toString.call("+
            zc.comp(zc.car(args))+") === '[object Array]')";
    }

    if (fn == "number_q") {
        if (zc.check(fn,args,1,1))
            return "(typeof "+zc.comp(zc.car(args))+" === 'number')";
    }

    if (fn == "boolean_q") {
        if (zc.check(fn,args,1,1))
            return "(typeof "+zc.comp(zc.car(args))+" === 'boolean')";
    }

    if (fn == "string_q") {
        if (zc.check(fn,args,1,1))
            return "(typeof "+zc.comp(zc.car(args))+" === 'string')";
    }

    if (fn == "length") {
        if (zc.check(fn,args,1,1)) return zc.comp(zc.car(args))+".length";
    }

    if (fn == "null_q") {
        if (zc.check(fn,args,1,1)) return "("+zc.comp(zc.car(args))+".length==0)";
    }

    if (fn == "not") {
        if (zc.check(fn,args,1,1))
            return "!("+zc.comp(zc.car(args))+")";
    }

    if (fn == "cons") {
        if (zc.check(fn,args,2,2))
            return "["+zc.comp(zc.car(args))+"].concat("+zc.comp(zc.cadr(args))+")";
    }

    if (fn == "append") {
        if (zc.check(fn,args,1,-1)) {
            var r=zc.comp(zc.car(args));
            for (var i=1; i<args.length; i++) {
                r+=".concat("+zc.comp(args[i])+")";
            }
            return r;
        }
    }

    if (fn == "car") {
        if (zc.check(fn,args,1,1))
            return zc.comp(zc.car(args))+"[0]";
    }

    if (fn == "cadr") {
        if (zc.check(fn,args,1,1))
            return zc.comp(zc.car(args))+"[1]";
    }

    if (fn == "caddr") {
        if (zc.check(fn,args,1,1))
            return zc.comp(zc.car(args))+"[2]";
    }

    if (fn == "cdr") {
        if (zc.check(fn,args,1,1))
            return "zc.sublist("+zc.comp(zc.car(args))+",1)";
    }

    if (fn == "eq_q") {
        if (zc.check(fn,args,2,2))
            return zc.comp(zc.car(args))+"=="+
            zc.comp(zc.cadr(args));
    }


    var infix = [["+","+"],
                 ["string_append", "+"],
                 ["-","-"],
                 ["*","*"],
                 ["/","/"],
                 ["%","%"],
                 ["<","<"],
                 [">",">"],
                 ["<=","<="],
                 [">=",">="],
                 ["=","=="],
                 ["and","&&"],
                 ["or","||"],
                 ["modulo","%"]];

    for (var i=0; i<infix.length; i++) {
        if (fn == infix[i][0]) return zc.infixify(infix[i][1],args);
    }

    if (fn == "set_e") {
        if (zc.check(fn,args,2,2))
            return zc.comp(zc.car(args))+"="+zc.comp(zc.cadr(args));
    }

    if (fn == "try") {
        if (zc.check(fn,args,2,2))
            return "try {"+zc.comp(zc.car(args))+"} catch (e) { "+zc.comp(zc.cadr(args))+" }";
    }

    // heart of darkness
    if (fn == "eval_string") {
        if (zc.check(fn,args,1,1))
            return "eval(zc.comp(zc.parse_tree("+zc.comp(zc.car(args))+")))";
    }

    // js intrinsics
    if (fn == "js") {
        if (zc.check(fn,args,1,1)) {
            var v=zc.car(args);
            // remove the quotes to insert the literal string
            return v.substring(1,v.length-1);
        }
    }

    if (fn == "new") {
        return "new "+zc.car(args)+"( "+zc.comp(zc.cadr(args))+")";
    }

    return false;
};

zc.char_is_number = function(c) {
    switch (c) {
        case "0": return true; break;
        case "1": return true; break;
        case "2": return true; break;
        case "3": return true; break;
        case "4": return true; break;
        case "5": return true; break;
        case "6": return true; break;
        case "7": return true; break;
        case "8": return true; break;
        case "9": return true; break;
    }
    return false;
};

zc.is_number = function(str) {
    return zc.char_is_number(str[0]);
};

zc.comp = function(f) {
//    console.log(f);
    try {
        // string, number or list?
        if (typeof f == "string") return f;

        // if null list
        if (f.length==0) return "[]";

        // apply args to function
        if (typeof zc.car(f) == "string") {
            // if it's a number
            if (zc.is_number(zc.car(f))) return zc.car(f);
            if (zc.car(f)[0]=="\"") return zc.car(f);

            var fn=zc.car(f);
            var args=zc.cdr(f);

            // look for a core form
            var r = zc.core_forms(fn,args);
            if (r) return r;

            // fallthrough to outer javascript environment
            return fn+"("+zc.list_map(zc.comp,args).join()+")";
        } else {
            // plain list
            return zc.list_map(zc.comp,f).join("\n");
        }
    } catch (e) {
        zc.to_page("output", "An error in parsing occured on "+f.toString());
        zc.to_page("output", e);
        zc.to_page("output", e.stack);
        return "";
    }
};

zc.compile_code = function(scheme_code) {
    var parse_tree=zc.parse_tree("("+scheme_code+")");
//    alert(JSON.stringify(do_syntax(parse_tree)));
    return zc.comp(do_syntax(parse_tree));
};


zc.compile_code_unparsed = function(scheme_code) {
    var parse_tree=zc.parse_tree("("+scheme_code+")");
    return zc.comp(parse_tree);
};

zc.load = function(url) {
    var xmlHttp = new XMLHttpRequest();
    xmlHttp.open( "GET", url, false );
    xmlHttp.send( null );
    var str=xmlHttp.responseText;
    return "\n/////////////////// "+url+"\n"+zc.compile_code(str)+"\n";
};

zc.load_unparsed = function(url) {
    var xmlHttp = new XMLHttpRequest();
    xmlHttp.open( "GET", url, false );
    xmlHttp.send( null );
    var str=xmlHttp.responseText;
    return "\n/////////////////// "+url+"\n"+zc.compile_code_unparsed(str)+"\n";
};


zc.to_page = function(id,html)
{
    var div=document.createElement("div");
    div.id = "foo";
    div.innerHTML = html;
    document.getElementById(id).appendChild(div);
};

function init() {

    jQuery(document).ready(function($) {

        // load and compile the syntax parser
        var syntax_parse=zc.load_unparsed("scm/syntax.jscm");
        try {
            //        console.log(syntax_parse);
            do_syntax=eval(syntax_parse);
        } catch (e) {
            zc.to_page("output", "An error occured parsing syntax of "+syntax_parse);
            zc.to_page("output",e);
            zc.to_page("output",e.stack);
        }

        var js=zc.load("/static/scm/base.scm");
        js+=zc.load("/static/scm/webgl.scm");
        js+=zc.load("/static/scm/texture.scm");
        js+=zc.load("/static/scm/maths.scm");
        js+=zc.load("/static/scm/data.scm");
        js+=zc.load("/static/scm/shaders.scm");
        js+=zc.load("/static/scm/state.scm");
        js+=zc.load("/static/scm/scene.scm");
        js+=zc.load("/static/scm/primitive.scm");
        js+=zc.load("/static/scm/renderer.scm");
        js+=zc.load("/static/scm/fluxus.scm");
        js+=zc.load("/static/scm/gfx.scm");
        var el = document.getElementById(id);
        var code = el.innerHTML;
        js += "\n///////////////// code from sketch follows\n";
        js += "\n"+zc.compile_code(code);
        zc.to_page("compiled",js);

        try {
            eval(js);
        } catch (e) {
            zc.to_page("output", "An error occured while evaluating ");
            zc.to_page("output",e);
            zc.to_page("output",e.stack);
        }
    });
}


/**
 * Provides requestAnimationFrame in a cross browser way.
 */
 var requestAnimFrame = (function() {
    return window.requestAnimationFrame ||
    window.webkitRequestAnimationFrame ||
    window.mozRequestAnimationFrame ||
    window.oRequestAnimationFrame ||
    window.msRequestAnimationFrame ||
    function(/* function FrameRequestCallback */ callback, /* DOMElement Element */ element) {
    window.setTimeout(callback, 1000/60);    };
    })();
