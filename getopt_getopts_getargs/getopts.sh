echo $*

while getopts ":a:b:c" opt;
do
    echo "-->" $opt
	case $opt in
        a ) echo $OPTARG
            echo "a $OPTIND"
            echo "---";;
        b ) echo $OPTARG
            echo "b $OPTIND"
            echo "---";;
        c ) echo "c $OPTIND"
            echo "---";;
        \? ) echo $opt
            echo "unsupported option"
            echo "---";;
        : ) echo "Error: option need OPTARG"
            echo "---"
            exit 1;;
    esac
done

echo $OPTIND
shift $(($OPTIND - 1))
#通过shift $(($OPTIND - 1))的处理，$*中就只保留了除去选项内容的参数，可以在其后进行正常的shell编程处理了。
echo $0
echo $*
