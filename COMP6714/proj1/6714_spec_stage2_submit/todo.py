import torch
from collections import defaultdict
from config import config
import torch.nn.functional as F
from torch.nn._functions.thnn import rnnFusedPointwise as fusedBackend
from torch.nn.utils.rnn import pack_padded_sequence, pad_packed_sequence

_config = config()

def last_index(mylist, myvalue):
    return len(mylist) - mylist[::-1].index(myvalue) - 1

def evaluate(golden_list, predict_list):
    '''
    This method computes the F1 score of the given predicted tags and golden tags.
    :param golden_list:
    :param predict_list:
    :return:
    '''

    tp = 0
    ground_truth = 0
    predict_tags = 0

    for i in range(len(golden_list)):

        golden = golden_list[i]
        predict = predict_list[i]

        ground_truth += len([1 for x in golden_list[i] if x.startswith('B-')])
        predict_tags += len([1 for x in predict_list[i] if x.startswith('B-')])

        try:
            golden_tar_start = golden.index('B-TAR')
        except ValueError:
            golden_tar_start = -1

        try:
            golden_tar_end = last_index(golden, 'I-TAR')
        except ValueError:
            golden_tar_end = golden_tar_start

        try:
            golden_hyp_start = golden.index('B-HYP')
        except ValueError:
            golden_tar_start = -1

        try:
            golden_hyp_end = golden.index('I-HYP')
        except ValueError:
            golden_hyp_end = golden_hyp_start

        if golden[golden_tar_start:golden_tar_end + 1] == predict[golden_tar_start:golden_tar_end+1] and golden_tar_start != -1and golden_tar_end < len(golden):
            if golden_tar_end + 1 == len(golden):
                tp += 1
            elif predict[golden_tar_end+1] != 'I-TAR':
                tp += 1

        if golden[golden_hyp_start:golden_hyp_end + 1] == predict[golden_hyp_start:golden_hyp_end+1] and golden_hyp_start != -1 and golden_hyp_end < len(golden):
            if golden_hyp_end + 1 == len(golden):
                tp += 1
            elif predict[golden_hyp_end+1] != 'I-HYP':
                tp +=1

    precision = tp / predict_tags
    recall = tp / ground_truth
    f1_score = 2 * precision * recall / (precision + recall)

    return f1_score


def new_LSTMCell(input_, hidden, w_ih, w_hh, b_ih=None, b_hh=None):
    if input_.is_cuda:
        igates = F.linear(input_, w_ih)
        hgates = F.linear(hidden[0], w_hh)
        state = fusedBackend.LSTMFused.apply
        return state(igates, hgates, hidden[1]) if b_ih is None else state(igates, hgates, hidden[1], b_ih, b_hh)

    hx, cx = hidden
    gates = F.linear(input_, w_ih, b_ih) + F.linear(hx, w_hh, b_hh)

    ingate, forgetgate, cellgate, outgate = gates.chunk(4, 1)
    ingate = torch.sigmoid(ingate)
    forgetgate = torch.sigmoid(forgetgate)
    cellgate = torch.tanh(cellgate)
    outgate = torch.sigmoid(outgate)

    cy = (forgetgate * cx) + ((1 - forgetgate) * cellgate)
    hy = outgate * torch.tanh(cy)

    return hy, cy


def get_char_sequence(model, batch_char_index_matrices, batch_word_len_lists):
    input_char_embeds = model.char_embeds(batch_char_index_matrices)
    input_char_embeds = input_char_embeds.view(input_char_embeds.shape[0] * input_char_embeds.shape[1], input_char_embeds.shape[2], input_char_embeds.shape[3])
    input_word_len_embeds = batch_word_len_lists.view(batch_word_len_lists.shape[0] * batch_word_len_lists.shape[1])

    char_idx, sorted_batch_word_len_list = model.sort_input(input_word_len_embeds)
    sorted_input_embeds = input_char_embeds[char_idx]
    _, desorted_indices = torch.sort(char_idx, descending=False)

    output_sequence = pack_padded_sequence(sorted_input_embeds, lengths=sorted_batch_word_len_list.data.tolist(),
                                           batch_first=True)
    output_sequence, state = model.char_lstm(output_sequence)
    output_sequence, _ = pad_packed_sequence(output_sequence, batch_first=True)
    output_sequence = output_sequence[desorted_indices]

    normal = output_sequence[0, input_word_len_embeds[0] - 1, :config.hidden_dim]
    reverse = output_sequence[0, 0, config.hidden_dim:]
    result = torch.cat([normal, reverse], dim=-1)
    for i in range(1,input_word_len_embeds.shape[0]):
        normal = output_sequence[i, input_word_len_embeds[i] - 1, :config.hidden_dim]
        reverse = output_sequence[i, 0, config.hidden_dim:]
        sub_res = torch.cat([normal, reverse], dim=-1)
        result = torch.cat([result, sub_res])
    result = result.view(batch_char_index_matrices.shape[0], batch_char_index_matrices.shape[1], -1)
    return result

if __name__ == '__main__':
    golden_list = [['B-TAR', 'I-TAR', 'O', 'B-HYP'], ['B-TAR', 'O', 'O', 'B-HYP']]
    predict_list = [['B-TAR', 'O', 'O', 'O'], ['B-TAR', 'O', 'B-HYP', 'I-HYP']]
    f1 = evaluate(golden_list, predict_list)
    print(f1)


'''
f1 = evaluate(golden_list, predict_list)
some test cases:
golden_list = [['B-TAR', 'I-TAR', 'I-TAR', 'B-HYP'], ['B-TAR', 'O', 'O', 'B-HYP']]
predict_list = [['B-TAR', 'O', 'O', 'O'],            ['B-TAR', 'O', 'B-HYP', 'I-HYP']]



golden_list = [['B-TAR', 'I-TAR', 'I-TAR', 'B-HYP'], ['B-TAR', 'O', 'O', 'B-HYP']]
predict_list = [['B-TAR', 'O', 'B-HYP', 'O'], ['B-TAR', 'O', 'B-HYP', 'I-HYP']]


golden_list = [['B-TAR', 'I-TAR', 'I-TAR', 'B-HYP'], ['B-TAR', 'O', 'O', 'B-HYP']]
predict_list = [['B-TAR', 'O', 'B-HYP', 'I-HYP'], ['B-TAR', 'O', 'B-HYP', 'I-HYP']]
'''