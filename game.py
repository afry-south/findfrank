import requests
import json
import sys
from collections import defaultdict
import random

token = input('enter bot token\n')
admin = input('enter admin email\n')
emails = input("enter emails. Example: hannes.sandberg@afconsult.com,daniel.odin@afry.com\n").split(',')
print(emails)
headers = {'Authorization' : 'Bearer ' + token}

def getUserId(email):
    url = 'https://slack.com/api/users.lookupByEmail'
    params = {'email' : email}
    res = requests.get(url, params=params, headers=headers)
    id = json.loads(res.text)['user']['id']
    return id


def sendMessage(userId, message):
    url = 'https://slack.com/api/chat.postMessage'
    data = {"text" : message, "channel" : userId}
    res = requests.post(url, headers=headers, data=data)
    return res


def createDeck():
    deck = []
    for i in range(1, 14):
        deck.append('hjärter '+str(i))
        deck.append('spader '+str(i))
        deck.append('ruter '+str(i))
        deck.append('klöver '+str(i))
    return deck


#4*4 kort + frank + bomb
def createBoard():
    deck = createDeck()
    random.shuffle(deck)
    board = deck[:14]
    board.append('f')
    board.append('b')
    random.shuffle(board)
    return board

def rightOrLeft(findex, cindex, card):
    if findex % 4 > cindex % 4:
        return 'Frank är vänster om ' + card
    elif findex % 4 < cindex % 4:
        return 'Frank är höger om ' + card
    else:
        return ''

def upOrDown(findex, cindex, card):
    if int(findex / 4) > int(cindex / 4):
        return 'Frank är nedanför ' + card
    elif int(findex / 4) < int(cindex / 4):
        return 'Frank är ovanför ' + card
    else:
        return ''

def createClues(board):
    clues = []
    for card in board:
        if card != 'f' and card != 'b':
            cindex = board.index(card)
            clue1 = rightOrLeft(findex, cindex, card)
            if clue1 != '':
                clues.append(clue1)
            clue2 = upOrDown(findex, cindex, card)
            if clue2 != '':
                clues.append(clue2)
            
    random.shuffle(clues)
    return clues

adminId=getUserId(admin)
board = createBoard()
findex=board.index('f')
bindex = board.index('b')
boardString=",".join(board)
print(boardString)
sendMessage(adminId, boardString)
clues=createClues(board)
print(clues)
users = defaultdict(dict)

#sendMessage(getUserId('frank.camara@afconsult.com'), 'Hej, får vi använda ditt namn och bild i vårt spel. Svara i #random kanalen tack!')
#sendMessage(getUserId('lars.korduner@afconsult.com'), 'Hej Lars')

for email in emails:
    users[email]=getUserId(email)

for user in users:
    sendMessage(users[user], 'Frank har försvunnit under mystiska omständigheter! Senast sågs han gömd i denna kortlek - kasta er in och släpp honom fri. Men se upp! En skojare har klämt in en bomb i kortleken i hopp om att säkerställa misslyckande. Använd de utströdda ledtrådarna, se igenom skojarens lustigheter, undvik bomben och rädda Frank ut ur kortleken!')

randomUsers= list(users.keys())
random.shuffle(randomUsers)
impostors = randomUsers[:1]

for impostor in impostors:
    sendMessage(users[impostor], 'Hej, du är en skojare, ditt uppdrag är att lura de andra deltagarna med falska ledtrådar.\nBomben är på rad: ' + str(int(bindex/4) + 1) + ' och kolumn: ' + str(int(bindex%4) + 1) + '\nFrank är på rad: '+ str(int(findex/4) + 1) + ' och kolumn: ' + str(int(findex%4) + 1))

while True:
    for user in users:
        adminInput = input('press 1 for sending clue to ' + user + ' press anything else to continue'+ '\n')
        print(adminInput)
        if adminInput == '1':
            sendMessage(users[user], clues[0])
            print('message sent to ' + user + ' message ' + clues[0])
            random.shuffle(clues)


for user in users:
    sendMessage(users[user], "test")
