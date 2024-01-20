import json
import os

# Directory where the data files are located
data_dir = r"C:\Users\Admin\OneDrive\Documents\repos\SGQR-Pro-Max\backend\scripts\uen_data\full_uen_filtered_list"

# Initialize an empty list to hold all the 'uen' values from all files
all_uen_array = []

# Iterate over each file in the directory
for file_name in os.listdir(data_dir):
    # Construct full file path
    file_path = os.path.join(data_dir, file_name)
    
    # Check if the file is a file and not a directory (and you might want to check file extension if needed)
    if os.path.isfile(file_path):
        # Open and read the file
        with open(file_path, 'r') as file:
            # Load data using json module
            data = json.load(file)

            # Extracting the 'uen' values and adding them to the array
            uen_array = [entity['uen'] for entity in data]
            
            # Extend the main list with the new UENs
            all_uen_array.extend(uen_array)

# Print or use the all_uen_array as needed
print("number of uens: " + str(len(all_uen_array)))

ten_character_uens = []
nine_character_uens = []

for i in all_uen_array:
    if len(i) == 10:
        ten_character_uens.append(i)
    else:
        nine_character_uens.append(i)

second_last_char_10char_is_num = 0

last_char_9char_is_num = 0

last_char_10char_is_num = 0

for i in ten_character_uens:
    if i[8].isalpha():
        second_last_char_10char_is_num += 1

for i in ten_character_uens:
    if i[9].isalpha():
        last_char_10char_is_num += 1        

for i in nine_character_uens:
    if i[8].isalpha():
        last_char_9char_is_num += 1

print("number of 9 char uens: " + str(len(nine_character_uens)))

print("number of 10 char uens: " + str(len(ten_character_uens)))

print("number of 9 char uens wtih last char being alphabet: " + str(last_char_9char_is_num))

print("number of 10 char uens wtih 2nd last char being alphabet: " + str(second_last_char_10char_is_num))

print("number of 10 char uens wtih last char being alphabet: " + str(last_char_10char_is_num))