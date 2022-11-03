class GuacUtils
{
	GuacUtils._();
///pass in a list of strings and get the properly formatted output. This function is infallible so no result type is necessary.
	static String encode(List<String> cypher) {
			//return an empty string if the list of strings is empty;
			if (cypher.isEmpty) {
					return '';
			}

			//replace each string with that string's length, a period, the string iself, and a comma.
			var result = '';
			//combine all the modified strings
			for (var s in cypher) {
					result = result + ("${s.length}.$s,");
			} 

			//replace the final comma with a semicolon
			result = result.substring(0, result.length -1);
			result = "$result;";

			//return the string
			return result;
	}

	///pass in a properly formatted string and get a list of strings
	static List<String> decode(String str)  {
			//If the input string is empty, return an empty list and don't waste any more CPU time
			if (str.isEmpty) {
					return [];
			}

			//create an index into the list
			var idx = 0;

			//create a list of strings, this is what will be returned
			List<String> result = [];

			//convert the input string into a list of its component characters
			var chars = str.split('');
			//begin an infinite loop
			while (true) {
					//Look at the index and create a string of all the numerical characters 
					//connected to it, building up a number
					var distStr = "";
				
					while (num.tryParse((chars[idx])) != null) {
							distStr += chars[idx];
							idx += 1;
					}
					if (idx >= 1) {
							idx -= 1;
					}

					//if that number is a real number, save it as a number type variable
					int? distance = int.tryParse(distStr);

					//increment the index
					idx += 1;

					//if the index is on a period (what it should be) continue, otherwise return early.
					if (chars[idx] != '.') {
							break;
					}

					//increment the index
					idx += 1;

					//Create a substring of the characters between the index and the index plus the number calculated earlier
					var addition = chars.sublist(idx, distance! + idx);

					//add the substring to the list of strings that will be returned
					result.add(addition.join(''));

					//increment the index the length of the substring that was taken
					idx += distance;

					//If the index is beyond the end of the list, something is wrong so return early
					if (idx >= chars.length) {
							break;
					}         

			//stop if the next char is not a ','
					if (chars[idx] == ',') {
						//do nothing
					} 
					else {
						break;
					}

					//increment the index and go through the loop again.
					idx += 1;
					continue;
			}

			//once outside the loop, return the list of strings.
			return result;
	}

}