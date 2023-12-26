#!/bin/bash
# Here is the code for playing Blackjack game 
# Create a file with touch command 
#give that file executable permission 
#save the file as black.sh
#to run ./black.sh in terminal
#randomly playable game 
#you just need to press p and h  
getopts "d:" message_delay

message_delay=${OPTARG:-"1"}
#declaring player hand and dealer hand
declare -a deck card_with_player card_on_dealer
#function creating cards and its types
function create_deck
{
    cards=(
        "Two|2"
        "Three|3"
        "Four|4"
        "Five|5"
        "Six|6"
        "Seven|7"
        "Eight|8"
        "Nine|9"
        "Ten|10"
        "Jack|10"
        "Queen|10"
        "King|10"
        "Ace|1"
    )

    suites=(
        "Diamonds"
        "Hearts"
        "Clubs"
        "Spades"
    )

    for suite in ${suites[@]}; do
        for card in ${cards[@]}; do
            echo "$suite|$card"
        done
    done
}
#defining a function for card deck
function card_deck
{
    echo "$1" | cut --delimiter="|" --fields="1,1"
}
#card name function
function name_of_card
{
    echo "$1" | cut --delimiter="|" --fields="2,2"
}
#calculation of card total
function card_total
{
    echo "$1" | cut --delimiter="|" --fields="3,3"
}
#In case if the card is ace
function if_ace
{
    [[ "$(name_of_card $1)" == "Ace" ]]
}
#In case if the card is faced card i.e jack, queen and king
function faced_card
{
    pattern='^(Jack|Queen|King)$'
    [[ "$(name_of_card $1)" =~ $pattern ]]
}

function cards_name
{
    echo "$(name_of_card $1) of $(card_deck $1)"
}
#calc name of card and its value
function cards_P
{
    if (faced_card $1 || if_ace $1); then
        name=$(name_of_card $1)
        name=${name:0:1}
    else
        name="$(card_total $1)"
    fi

    suite=$(card_deck $1)

    echo "$name-${suite:0:1}"
}
#hand value of the player
function hand_value
{
    sorted_hand=($(echo "$@" | tr ' ' "\n" | sort --field-separator='|' --key='3,3n'))

    declare -i value=0

    for card in ${sorted_hand[@]}; do
        card_total=$(card_total $card)
        value=$((value + card_total))
    done

    if [[ $value -lt 12 ]]; then
        for card in ${sorted_hand[@]}; do
            if if_ace $card; then
                value+=10
            fi

            if [[ $value -gt 12 ]]; then
                break
            fi
        done
    fi

    echo $value
}

function hand_abbreviation
{
    echo -n "( "
    for card in $@; do
        echo -n "$(cards_P $card) "
    done
    echo ")"
}
#Unless if is above 21
function busted
{
    [[ $(hand_value $@) -gt 21 ]]
}
#Unless if it is exact 21
function got_blackjack
{
    [[ $# -eq 2 && $(hand_value $@) -eq 21 ]] 
}

function message 
{
    echo -e $@
    sleep $message_delay
}
#asking dealer to draw card
function ask_dealer
{
    card=${deck[0]}
    deck=(${deck[@]:1})
    card_on_dealer+=($card)

    message "\nDealer draws $(cards_name $card)"
}
#asking player to draw card
function ask_player
{
    card=${deck[0]}
    deck=(${deck[@]:1})
    card_with_player+=($card)

    message "\nPlayer draws $(cards_name $card)"
}
#asking player ro hit or stay
#Unless if it is above 21 then busted
function player_card_turn
{
    input=""

    until [[ $input == "s" ]]; do
        message "\nPlayer hand: $(hand_value ${card_with_player[@]}) $(hand_abbreviation ${card_with_player[@]})\n\nhit or stay?"

        read -s -n 1 input
        input=${input,,}

        if [[ $input == "h" ]]; then
            ask_player

            if busted ${card_with_player[@]}; then
                return 1;
            fi
        fi
    done

    message "\nPlayer stays."

    return 0;
}
#show dealer card value
#ask dealer
#if above 21 then busted
function dealer_card_turn
{
    message "\nDealer reveals $(cards_name ${card_on_dealer[1]})."

    no_of_dealer_card=$(hand_value ${card_on_dealer[@]})

    message "\nDealer hand: $no_of_dealer_card $(hand_abbreviation ${card_on_dealer[@]})."

    player_card_total=$(hand_value ${card_with_player[@]})

    until [[ $no_of_dealer_card -ge 17 || $no_of_dealer_card -gt $player_card_total ]]; do
        ask_dealer

        no_of_dealer_card=$(hand_value ${card_on_dealer[@]})

        message "\nDealer hand: $no_of_dealer_card $(hand_abbreviation ${card_on_dealer[@]})."
    done

    if busted ${card_on_dealer[@]}; then
        return 1;
    fi

    message "\nDealer stays."

    return 0
}
#decide who won or busted or draw
function start_new
{
    deck=($(create_deck | shuf))

    card_with_player=(${deck[@]:0:2})
    card_on_dealer=(${deck[@]:2:2})

    deck=(${deck[@]:4})

    message "\nPlayer draws $(cards_name ${card_with_player[0]}) and $(cards_name ${card_with_player[1]})."

    if got_blackjack ${card_with_player[@]}; then
        if got_blackjack ${card_on_dealer[@]}; then
            message "\nDealer has $(cards_name ${card_on_dealer[0]}) and $(cards_name ${card_on_dealer[1]})."

            message "\nblackjack. Game is a draw."
        else
            message "\nBlackjack!"
        fi

        return
    elif got_blackjack ${card_on_dealer[@]}; then
        message "\nDealer has $(cards_name ${card_on_dealer[0]}) and $(cards_name ${card_on_dealer[1]})."

        message "\nDealer has blackjack. Dealer wins."
        return
    fi

    message "\nDealer shows $(cards_name ${card_on_dealer[0]})."

    if ! player_card_turn; then
        message "\nPlayer is busted."
        return
    fi

    if ! dealer_card_turn; then
        message "\nDealer is busted."
        return
    fi

    player_card_total=$(hand_value ${card_with_player[@]})
    no_of_dealer_card=$(hand_value ${card_on_dealer[@]})

    message "\nPlayer has $player_card_total. Dealer has $no_of_dealer_card."

    if [[ $player_card_total -gt $no_of_dealer_card ]]; then
        message "\nPlayer wins."
    elif [[ $player_card_total -lt $no_of_dealer_card ]]; then
        message "\nDealer wins."
    else
        message "\ndraw."
    fi
}
#continue same again
#ask to play or quit the game
function loop_again
{
    input=""

    until [[ $input == "q" ]]; do
        message "\n play or quit?" 
        read -s -n 1 input
        input=${input,,}

        if [[ $input == "p" ]]; then
            start_new
        fi
    done

    return 0
}

loop_again

exit 0