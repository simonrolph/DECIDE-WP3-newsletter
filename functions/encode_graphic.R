# from: https://stackoverflow.com/questions/50244709/how-to-store-r-ggplot-graph-as-html-code-snippet

encode_graphic <- function(g) {
  png(tf1 <- tempfile(fileext = ".png"))  # Get an unused filename in the session's temporary directory, and open that file for .png structured output.
  print(g)  # Output a graphic to the file
  dev.off()  # Close the file.
  txt <- RCurl::base64Encode(readBin(tf1, "raw", file.info(tf1)[1, "size"]), "txt")  # Convert the graphic image to a base 64 encoded string.
  myImage <- htmltools::HTML(sprintf('<img src="data:image/png;base64,%s">', txt))  # Save the image as a markdown-friendly html object.
  return(myImage)
}
