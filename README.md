# Gaussian Mixture Models for Speaker Identification

The objective of this project is to implement a text-independent Speaker Identification (SI) system based on Gaussian Mixture Models (GMMs). This system takes a speech utterance from an unknown speaker and provides the name or identification code of that speaker.

The basis of a GMM-based speaker identification system is that each speaker in the system is represented by a specific statistical model, which is a GMM. This model is built in the enrollment or training stage using speech from the particular speaker. In the speaker identification or test stage, given speech from an unknown speaker, the objective is to identify who is this individual by evaluating how well each of the GMMs in the system fits his/her voice. Finally, the system selects as the true speaker the one whose GMM produces the highest likelihood.

## Acknowledgements

University Carlos III of Madrid, Speech and Audio Processing.
