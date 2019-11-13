unit module Documentable::Utils::Text;

#| Converts Lists of Pod::Blocks to String
multi textify-pod (Any:U        , $?) is export { '' }
multi textify-pod (Str:D      \v, $?) is export { v }
multi textify-pod (List:D     \v, $separator = ' ') is export { v».&textify-pod.join($separator) }
multi textify-pod (Pod::Block \v, $?) is export {
    # core module
    use Pod::To::Text;
    pod2text v;
}
