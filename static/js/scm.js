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

zc.comp_lambda = function(args) {
    var expr=zc.cdr(args);
    var nexpr=expr.length;
    var last=expr[nexpr-1];
    var eexpr=zc.sublist(expr,0,nexpr-1);
    var lastc="";

    if (zc.car(last)=="cond") {
        lastc=zc.comp_cond_return(zc.cdr(last));
    } else {
        if (zc.car(last)=="if") {
            lastc=zc.comp_if_return(zc.cdr(last));
        } else {
            if (zc.car(last)=="when") {
                lastc=zc.comp_when_return(zc.cdr(last));
            } else {
                lastc="return "+zc.comp(last);
            }
        }
    }

    return "function ("+zc.car(args).join()+")\n"+
        "{"+zc.list_map(zc.comp,eexpr).join("\n")+
        "\n"+lastc+"\n}\n";
};

zc.comp_let = function(args) {
    var fargs = zc.car(args);
    largs = [];
    fargs.forEach(function(a) { largs.push(a[0]); });
    return "("+zc.comp_lambda([largs].concat(zc.cdr(args)))+"("+
        zc.list_map(function(a) { return zc.comp(a[1]); },fargs)+" ))\n";
};

zc.comp_cond = function(args) {
    if (zc.car(zc.car(args))==="else") {
        return zc.comp(zc.cdr(zc.car(args)));
    } else {
        return "if ("+zc.comp(zc.car(zc.car(args)))+") {\n"+
            zc.comp(zc.cadr(zc.car(args)))+"\n} else {\n"+
            zc.comp_cond(zc.cdr(args))+"\n}";
    }
};

zc.comp_cond_return = function(args) {
    if (zc.car(zc.car(args))==="else") {
        return "return "+zc.comp(zc.cdr(zc.car(args)));
    } else {
        return "if ("+zc.comp(zc.car(zc.car(args)))+") {\n"+
            "return "+zc.comp(zc.cadr(zc.car(args)))+"\n} else {\n"+
            zc.comp_cond_return(zc.cdr(args))+"\n}";
    }
};

zc.comp_if = function(args) {
    return "if ("+zc.comp(zc.car(args))+") {\n"+
        zc.comp(zc.cadr(args))+"} else {"+
        zc.comp(zc.caddr(args))+"}";
};

zc.comp_if_return = function(args) {
    return "if ("+zc.comp(zc.car(args))+") {\n"+
        "return "+zc.comp(zc.cadr(args))+"} else {"+
        "return "+zc.comp(zc.caddr(args))+"}";
};

zc.comp_when = function(args) {
    return "if ("+zc.comp(zc.car(args))+") {\n"+
        zc.comp(zc.cdr(args))+"}";
};

zc.comp_when_return = function(args) {
    return "if ("+zc.comp(zc.car(args))+") {\n"+
        "return ("+zc.comp_lambda([[]].concat(zc.cdr(args)))+")() }";
};

zc.core_forms = function(fn, args) {
    // core forms
    if (fn == "lambda") return zc.comp_lambda(args);
    if (fn == "if") return zc.comp_if(args);
    if (fn == "when") return zc.comp_when(args);
    if (fn == "cond") return zc.comp_cond(args);
    if (fn == "let") return zc.comp_let(args);

    if (fn == "define") {
        return "var "+zc.car(args)+" = "+zc.comp(zc.cdr(args))+";";
    }

    if (fn == "list") {
        return "["+zc.list_map(zc.comp,args).join(",")+"]";
    }

    if (fn == "begin") {
        return "("+zc.comp_lambda([[]].concat(args))+")()";
    }

    if (fn == "list_ref") {
        return zc.comp(zc.car(args))+"["+zc.comp(zc.cadr(args))+"]";
    }

    if (fn == "list_replace") {
        return "(function() {"+
            "var _list_replace="+zc.comp(zc.car(args))+"\n"+
            "_list_replace["+zc.comp(zc.cadr(args))+"]="+
            zc.comp(zc.caddr(args))+";\n"+
            "return _list_replace;\n})()\n";
    }

    // iterative build-list version for optimisation
    if (fn == "build_list") {
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
        return "(function() {\n"+
            "var _foldl_fn="+zc.comp(zc.car(args))+";\n"+
            "var _foldl_val="+zc.comp(zc.cadr(args))+";\n"+
            "var _foldl_src="+zc.comp(zc.caddr(args))+";\n"+
            "for (var _foldl_i=0; _foldl_i<_foldl_src.length; _foldl_i++) {\n"+
            "_foldl_val=_foldl_fn(_foldl_src[_foldl_i],_foldl_val); }\n"+
            "return _foldl_val; })()";
    }

    if (fn == "list_q") {
        return "(typeof "+zc.comp(zc.car(args))+"==='array')";
    }

    if (fn == "length") {
        return zc.comp(zc.car(args))+".length";
    }

    if (fn == "null_q") {
        return "("+zc.comp(zc.car(args))+".length==0)";
    }

    if (fn == "not") {
        return "!("+zc.comp(zc.car(args))+")";
    }

    if (fn == "cons") {
        return "["+zc.comp(zc.car(args))+"].concat("+zc.comp(zc.cadr(args))+")";
    }

    if (fn == "append") {
        return zc.comp(zc.car(args))+".concat("+zc.comp(zc.cadr(args))+")";
    }

    if (fn == "car") {
        return zc.comp(zc.car(args))+"[0]";
    }

    if (fn == "cadr") {
        return zc.comp(zc.car(args))+"[1]";
    }

    if (fn == "caddr") {
        return zc.comp(zc.car(args))+"[2]";
    }

    if (fn == "cdr") {
        return "zc.sublist("+zc.comp(zc.car(args))+",1)";
    }

    if (fn == "eq_q") {
        return zc.comp(zc.car(args))+"=="+
            zc.comp(zc.cadr(args));
    }


    var infix = [["+","+"],
                 ["-","-"],
                 ["*","*"],
                 ["/","/"],
                 ["%","%"],
                 ["=","=="],
                 ["and","&&"],
                 ["or","||"]];

    for (var i=0; i<infix.length; i++) {
        if (fn == infix[i][0]) return zc.infixify(infix[i][1],args);
    }

    if (fn == "set_e") {
        return zc.comp(zc.car(args))+"="+zc.comp(zc.cadr(args));
    }

    if (fn == "try") {
        return "try {"+zc.comp(zc.car(args))+"} catch (e) { "+zc.comp(zc.cadr(args))+" }";
    }

    // js intrinsics
    if (fn == "js") {
        var v=zc.car(args);
        // remove the quotes to insert the literal string
        return v.substring(1,v.length-1);
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
};

zc.is_number = function(str) {
    return zc.char_is_number(str[0]);
};

zc.comp = function(f) {
//    console.log(f);

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
};

zc.compile_code = function(scheme_code) {
    var parse_tree=zc.parse_tree("("+scheme_code+")");
    //console.log(parse_tree);
    return zc.comp(parse_tree);
};

zc.load = function(url) {
    var xmlHttp = new XMLHttpRequest();
    xmlHttp.open( "GET", url, false );
    xmlHttp.send( null );
    var str=xmlHttp.responseText;
    //console.log(zc.compile_code(str));
    return "\n/////////////////// "+url+"\n"+zc.compile_code(str)+"\n";
};

zc.to_page = function(id,html)
{
    var div=document.createElement("div");
    div.id = "foo";
    div.innerHTML = html;
    document.getElementById(id).appendChild(div);
};

function init(id) {
    var js=zc.load("/static/scm/base.scm");
    js+=zc.load("/static/scm/webgl.scm");
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
    eval(js);
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
